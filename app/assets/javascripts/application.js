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

function lazyLoadElements() {
  var lazy_load_elements = $('[data-lazy-load-url]');

  if (lazy_load_elements.length > 0) {
    var lazy_load_element = $(lazy_load_elements[0]);

    var url    = lazy_load_element.data('lazy-load-url');
    var params = lazy_load_element.attr('data-lazy-load-params'); // data caches the result, that's why we use attr() instead

    lazy_load_element.removeAttr('data-lazy-load-url');
    lazy_load_element.removeAttr('data-lazy-load-params');

    $.ajax({
      url: url,
      method: (lazy_load_element.data('method') || 'GET'),
      data: params,
      dataType: 'script',
      complete: function() {
        lazyLoadElements();
      }
    });
  }
}

document.addEventListener('turbolinks:load', function() {
  $('.js-datepicker').datepicker(datepicker_options());

  lazyLoadElements();
});

$(document).ajaxStart(function() {
  $('.btn').addClass('disabled');
});

$(document).ajaxStop(function() {
  $('.btn').removeClass('disabled');
});

$(document).on('click', '.btn.disabled', function(e) {
  e.preventDefault();
  e.stopPropagation();
});
