$(document).ready(function() {
  var timeDifference = function(date1, date2) {
    var diff = diffi(date1, date2);
    var days = Math.floor(diff / (1000 * 24 * 60 * 60));
    diff = diff % (1000 * 24 * 60 * 60);
    var hours = Math.floor(diff / (1000 * 60 * 60));
    diff = diff % (1000 * 60 * 60);
    var minutes = Math.floor(diff / (1000 * 60));
    diff = diff % (1000 * 60);
    var seconds = Math.floor(diff / 1000);
    return [days, hours, minutes, seconds];
  }

  var diffi = function(date1, date2) {
    return Date.parse(date1) - Date.parse(date2);
  }

  $('<img>').attr("src", "/css/images/loading.gif").appendTo("#loading");
  $('<p>').text("this can take several seconds.").appendTo("#loading");
  $.getJSON('/history.json', function(response) {
    $.each(response, function(key, value) {
      var prevState = "";
      var prevDate = null;
      var desc = [];
      var points = [];
      var html = "<table align='center' width='100%'><tbody>";
      $.each(value, function(i) {
        if(prevState != value[i].status_name) {
          html += "<tr><td><strong>" + ((value[i].status_name == "") ? "undefined" : value[i].status_name) + "</strong></td><td>"+ $.datepicker.formatDate('dd-M-yy', new Date(value[i].change_date)) +"</td>";
          if(prevDate == null) {
            html += "<td colspan='4'>enters</td>";
          } else {
            var d = timeDifference(value[i].change_date, prevDate);
            html += "<td>" + d[0] + " days</td><td>" + d[1] + " hours</td><td>" + d[2] + " min</td><td>" + d[3] + " sec</td></tr>";
          }
          var pts = diffi(value[i].change_date, prevDate) / (1000 * 24 * 60 * 60);
          points.push(((prevDate != null) ? Math.round(pts * Math.pow(10,2))/Math.pow(10,2) : 0));
          desc.push(((value[i].status_name == '') ? "undefined" : value[i].status_name));
        }
        prevState = value[i].status_name;
        prevDate = value[i].change_date;
      });
      html += "</tbody></table>";
      jQuery('#div_' + key).html(html);
      barChart(key, points, desc);
    });
    $("#loading").html("");
    $("#container").css('display', 'block');
  });

  $(".modal").click(function(event) {
    event.preventDefault();
    var id = "div_" + $(this).attr("id").split('_')[1];
    $("#" + id).dialog({
      height: 400,
      width: 500,
      modal: true
    });
  });

  var barChart = function(story_id, points, desc) {
    var api = new jGCharts.Api();
    var val = Math.floor(Math.max.apply(Math, points) * 40);
    var height = (val > 100)? val : 100;
    var width = (desc.length * 13) + 150;
    var opt = {
      data: [points],
      axis_labels: ["B-" + story_id], 
      legend: desc,
      size:  width + 'x' + height,
      bar_width: 10,
      bar_spacing: 3
    };
    jQuery('<img>').attr('src', api.make(opt)).appendTo("#bar" + story_id);
  }
});
