# encoding: utf-8

require_relative 'table_sampler'

module CartoDB
  module Importer2
    class ContentGuesser

      COUNTRIES_COLUMN = 'name_'
      COUNTRIES_QUERY = "SELECT #{COUNTRIES_COLUMN} FROM admin0_synonyms"
      DEFAULT_MINIMUM_ENTROPY = 0.9
      ID_COLUMNS = ['ogc_fid', 'gid', 'cartodb_id']

      def initialize(db, table_name, schema, options, job=nil)
        @db         = db
        @table_name = table_name
        @schema     = schema
        @options    = options
        @job        = job
      end

      def enabled?
        @options[:guessing][:enabled] rescue false
      end

      def country_column
        return nil if not enabled?
        columns.each do |column|
          return column[:column_name] if is_country_column? column
        end
        nil
      end

      def columns
        @columns ||= @db[%Q(
          SELECT column_name, data_type
          FROM information_schema.columns
          WHERE table_name = '#{@table_name}' AND table_schema = '#{@schema}'
        )]
      end

      def is_country_column?(column)
        return false unless is_country_column_type? column
        return false unless metric_entropy(column) > minimum_entropy
        return country_proportion(column) > threshold
      end

      # See http://en.wikipedia.org/wiki/Entropy_(information_theory)
      # See http://www.shannonentropy.netmark.pl/
      #
      # Returns 0.0 if all elements in the column are repeated
      # Returns 1.0 if all elements in the column are different
      def metric_entropy(column)
        shannon_entropy(column) / Math.log(sample.count)
      end

      def shannon_entropy(column)
        sum = 0.0
        frequencies(column).each { |freq| sum += (freq * Math.log(freq)) }
        return -sum
      end

      # Returns an array with the relative frequencies of the elements of that column
      def frequencies(column)
        frequency_table = {}
        column_name_sym = column[:column_name].to_sym
        sample.each do |row|
          elem = row[column_name_sym]
          frequency_table[elem] += 1 rescue frequency_table[elem] = 1
        end
        length = sample.count.to_f
        frequency_table.map { |key, value| value / length }
      end

      def country_proportion(column)
        column_name_sym = column[:column_name].to_sym
        matches = sample.count { |row| countries.include? row[column_name_sym].gsub(/[^a-zA-Z\u00C0-\u00ff]+/, '').downcase }
        country_proportion = matches.to_f / sample.count
        log "country_proportion(#{column[:column_name]}) = #{country_proportion}"
        country_proportion
      end

      def log(msg)
        @job.log msg if @job
      end

      def sample
        @sample ||= TableSampler.new(@db, qualified_table_name, id_column, sample_size).sample
      end

      def id_column
        return @id_column if @id_colums
        columns.each do |column|
          if ID_COLUMNS.include? column[:column_name]
            @id_column = column[:column_name]
            return @id_column
          end
        end
        raise ContentGuesserException.new "Couldn't find an id column for table #{qualified_table_name}"
      end

      def threshold
        @options[:guessing][:threshold]
      end

      def is_country_column_type? column
        ['character varying', 'varchar', 'text'].include? column[:data_type]
      end

      def sample_size
        @options[:guessing][:sample_size]
      end

      def minimum_entropy
        @minimum_entropy ||= @options[:guessing].fetch(:minimum_entropy) rescue DEFAULT_MINIMUM_ENTROPY
      end

      def countries
        return @countries if @countries
        @countries = Set.new()
        geocoder_sql_api.fetch(COUNTRIES_QUERY).each do |country|
          @countries.add country[COUNTRIES_COLUMN]
        end
        @countries
      end

      def geocoder_sql_api
        @geocoder_sql_api ||= CartoDB::SQLApi.new(@options[:geocoder][:internal])
      end

      attr_writer :geocoder_sql_api

      def qualified_table_name
        %Q("#{@schema}"."#{@table_name}")
      end

    end

    class ContentGuesserException < StandardError; end

  end
end
