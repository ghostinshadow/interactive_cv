this.OpenLayer = {
  renderErrors: function(errors) {
    ErorrHendler.renderErrors(errors, '.open_layer_');
  },

  appendRecord: function(content) {
    var highlightContent = Highlight.initHighlight(content);
    highlightContent.appendTo('#open_layers');
    Highlight.highlight(highlightContent);
  },

  updateRecord: function(recordId, content) {
    var highlightContent = Highlight.initHighlight(content);
    $('tr[open_layer=' + recordId + ']').replaceWith(highlightContent);
    Highlight.highlight(highlightContent);
  },

  appendTable: function(tableHeader, content) {
    var highlightContent = Highlight.initHighlight(content);
    $('.no_records').replaceWith(tableHeader);
    highlightContent.appendTo('#open_layers');
    Highlight.highlight(highlightContent);
  }
}