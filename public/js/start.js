$(document).ready(function(){

  // Disable inputs after submission.
  $('.main').on('submit', 'form', function(e) {
    form_class = $(this).attr('class');
    switch(form_class) {
      case "package_form":
        $('input[type=submit]').attr('disabled', 'disabled');
      break;
      case "publish_form":
        // Confirm dialog in case of setting a package public.
        if(!confirm("You are going to set this package to public. Stop immediately if you don't know what you are doing!")) {
          e.preventDefault();
          return false;
        } else {
          $('input[type=submit]').attr('disabled', 'disabled');
        }
      break;
    }
  });

});