// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require jquery.form.min
//= require jquery-ui
//= require turbolinks
//= require bootstrap.min
//= require_self

function datepicker_options(options) {
  var result = $.datepicker.regional['en'];
  result['changeMonth'] = true;
  result['changeYear']  = true;
  result['yearRange']   = '-5:+0';
  result['dateFormat']  = 'dd.mm.yy';

  if (options) {
    $.each(options, function(key, value) {
      result[key] = value;
    });
  }

  return result;
}

document.addEventListener('turbolinks:load', function() {
  $('.js-datepicker').datepicker(datepicker_options());
});
