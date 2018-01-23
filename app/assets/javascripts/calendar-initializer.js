function eventCalendar() {
  var parameter = $('#calendar').attr('data-room-id');
  return $('#calendar').fullCalendar({
    locale: 'ru',
    contentHeight: 600,
    header: {
      left: 'month,agendaWeek,agendaDay',
      center: 'title'
    },
    views: {
      month: {
        buttonText: 'Месяц'
      },
      agendaWeek: {
        type: 'agenda',
        duration: {
          days: 7
        },
        buttonText: 'Неделя'
      },
      agendaDay: {
        type: 'agenda',
        duration: {
          days: 1
        },
        buttonText: 'День'
      }
    },
    buttonText: {
      today: 'Сегодня'
    },
    events: '/events.json?room_id=' + parameter,
    timeFormat: 'HH:mm',
    displayEventEnd: true,
    dayClick: function(date, jsEvent, view, resourceObj) {
      var d = new Date();
      d.setHours(0, 0, 0);
      if (date >= d)
        location.href = '/events/new?room_id=' + parameter;
    },
    eventRender: function(event, element) {
      $(element).popover({
        html : true,
        title: event.title,
        content: function(){
          var c = "Время проведение: " + event.start.format("hh.mm") + " - " + event.end.format("hh.mm");
          c += "<br>" + "Организатор: " + event.organizer.name + "<br>" + "Проводит: " + event.lector.name;
          c += "<hr>" + event.description;
          return c;
        },
        trigger: 'hover',
        placement: 'auto right',
        // delay: {"hide": 300 }
      })
    }
  });
};

function clearCalendar() {
  $('#calendar').fullCalendar('delete');
  $('#calendar').html('');
};

$(document).on('turbolinks:load', eventCalendar);
$(document).on('turbolinks:before-cache', clearCalendar);
