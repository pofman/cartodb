import UploadConfig from 'dashboard/common/upload-config';

export default {
  computed: {
    getHeaderTitleFromMode (mode) {
      if (this.mode === 'dataset') {
        return this.$t('DataPage.addDataset');
      } else if (this.mode === 'map') {
        return this.$t('MapsPage.createMap');
      } else if (this.mode === 'layer') {
        return this.$t('DataPage.addLayer');
      }
      return '';
    }
  },
  methods: {
    getUploadObject () {
      return {
        type: '',
        value: '',
        interval: 0,
        privacy: 'PRIVATE',
        progress: 0,
        // state: 'idle',
        service_item_id: '',
        service_name: '',
        option: '',
        content_guessing: true,
        type_guessing: true,
        create_vis: this.mode === 'map'
      };
    },
    validateUrl (url) {
      const urlregex = /^((http|https|ftp)\:\/\/)/g;

      if (url && urlregex.test(url)) {
        return {
          valid: true,
          msg: ''
        };
      } else {
        return {
          valid: false,
          msg: _t('data.upload-model.url-invalid')
        };
      }
    },
    validateFile (files, remainingByteQuota) {
      // Number of files
      if (files && files.length > 1) {
        return {
          valid: false,
          msg: _t('data.upload-model.one-file')
        };
      }

      // File name
      var name = files[0].name;
      if (!name) {
        return {
          valid: false,
          msg: _t('data.upload-model.file-defined')
        };
      }

      // File extension
      var ext = name.substr(name.lastIndexOf('.') + 1);
      if (ext) {
        ext = ext.toLowerCase();
      }
      if (!UploadConfig.fileExtensions.find(e => e === ext)) {
        return {
          valid: false,
          msg: _t('data.upload-model.file-extension')
        };
      }
      // File size
      if ((remainingByteQuota * UploadConfig.fileTimesBigger) < files[0].size) {
        return {
          valid: false,
          msg: _t('data.upload-model.file-size')
        };
      }
      return {
        valid: true,
        msg: ''
      };
    }
  }
};