this.ErorrHendler = {
  renderErrors: function(errors, formNamePrefix, removeOld) {
    removeOld = typeof removeOld !== 'undefined' ? removeOld : true;
    if (removeOld) {
      $('.control-group').removeClass('error');
      $('.control-group .error-info').remove();
    }
    if (errors) {
      for (var attr in errors) {
        $(formNamePrefix + attr).addClass('error')
          .append('<span class="error-info">' + errors[attr].join(', ') + '</span>');
      }
    } else {
      return false;
    }
  }
}