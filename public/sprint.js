$(document).ready(function() {
  $.getJSON("/sprints.json", function(response) {
    var sprints = $("#sprintSelect");
    $.each(response, function(i) {
      sprints.append($("<option />").val(response[i].name).text(response[i].name));
    });
  });

  $("#sprintSelect").change(function() {
    location.href = "/change_sprint?sprint=" + $(this).val();
  });
});
