$(document).ready(function() {

  var hoverIn = function () {
    this.sector.stop();
    this.sector.scale(1.1, 1.1, this.cx, this.cy);
    if (this.label) {
      this.label[0].stop();
      this.label[0].scale(1.5);
      this.label[1].attr({"font-weight": 800});
    }
  }

  var hoverOut = function () {
    this.sector.animate({scale: [1, 1, this.cx, this.cy]}, 500, "bounce");
    if (this.label) {
      this.label[0].animate({scale: 1}, 500, "bounce");
      this.label[1].attr({"font-weight": 400});
    }
  }

  var paintPieChart = function(id, radius, values, descriptions) {
    $(id).innerHTML = "";
    var width = jQuery(id).css('width');
    var paper = Raphael(id, width, 600);
    var pie = paper.g.piechart(radius + 20, radius + 10, radius, values, {legend: descriptions,
      legendpos: "south"});
    pie.hover(hoverIn, hoverOut);
  }

  $.ajax({
    url: "/status.json",
  method: "get",
  dataType: "json",
  success: function(res) {
    var definedPoints = 0, inProgressPoints = 0, blockedPoints = 0, donePoints = 0, inQaPoints = 0;
    $.each(res, function(i) {
      if(res[i].status == 'Defined') definedPoints += ((res[i].estimate != "-") ? parseInt(res[i].estimate) : 0);
      if(res[i].status == 'In Progress') inProgressPoints += ((res[i].estimate != "-") ? parseInt(res[i].estimate) : 0);
      if(res[i].status == 'Done') donePoints += ((res[i].estimate != "-") ? parseInt(res[i].estimate) : 0);      
      if(res[i].status == 'In QA') inQaPoints +=((res[i].estimate != "-") ? parseInt(res[i].estimate) : 0);
      if(res[i].status == 'Blocked') blockedPoints +=((res[i].estimate != "-") ? parseInt(res[i].estimate) : 0);    
    });
    paintPieChart('pie', 120, [definedPoints, inProgressPoints, donePoints, inQaPoints, blockedPoints], ["Defined - " + definedPoints + " points", 
                                                                                                          "In Progress - " + inProgressPoints + " points", 
                                                                                                          "Done - " + donePoints + " points", 
                                                                                                          "In QA - " + inQaPoints + " points", 
                                                                                                          "Blocked - " + blockedPoints + " points"]);
  },
  failure: function() {
  }
  });
});
