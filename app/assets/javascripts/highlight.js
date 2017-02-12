this.Highlight = {

  highlight: function (element) {
    setTimeout(function() {
      element.removeClass('highlight');
    }, 250);
  },
  refreshCounters: function(){
    var i = 1;
    $( " tr td:first-child").each(function(){
      $(this).html(i);
      i++;
    })
  },

  initHighlight: function (element) {
    return $(element).addClass('highlight');
  }

}