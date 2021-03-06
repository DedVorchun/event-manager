class EventsController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  before_action :check_user, only: [:edit, :update, :destroy]

  def index
    if params[:room_id]
      @events = Event.where(room_id: params[:room_id], archive: false).order(:begin_time)
    else
      dtn = DateTime.now
      @events = Event.where(archive: false).where("date > ? or (date = ? and end_time > ?)", dtn.strftime("%Y-%m-%d"), dtn.strftime("%Y-%m-%d"), dtn.strftime("%H:%M")).order(:date).order(:begin_time).paginate(page: params[:page], :per_page => 10)
    end
  end

  def archive
    @events = Event.where(archive: true).order(:date).reverse_order.order(:begin_time).paginate(page: params[:page], :per_page => 10)
  end

  def past
    dtn = DateTime.now
    @events = Event.where(archive: false).where("date < ? or (date = ? and end_time <= ?)", dtn.strftime("%Y-%m-%d"), dtn.strftime("%Y-%m-%d"), dtn.strftime("%H:%M")).order(:date).reverse_order.order(:begin_time).paginate(page: params[:page], :per_page => 10)
  end

  def new
    @event = Event.new
    @event.room_id = params[:room_id]
    @event.date = params[:date] ? params[:date] : DateTime.now.strftime("%d.%m.%Y")
    @event.begin_time = Time.parse("15:00")
    @event.end_time = Time.parse("15:30")
    @rooms = Room.all
    flash[:notice] = ""

    respond_to do |format|
      format.html do
        render partial: 'new'
      end
    end
  end

  def create
    @event = Event.new(event_params)
    @rooms = Room.all
    respond_to do |format|
      add_new_organizers_and_lectors

      if @event.save
        create_repeatly_events if params.permit(:repeatly).has_key? :repeatly

        format.html { redirect_to request.referrer }
      else
        flash[:notice] = @event.errors['text'].last
        format.html { render partial: 'new' }
      end
    end
  end

  def edit
    @event = Event.find(params[:id])
    @rooms = Room.all
    flash[:notice] = ""
    if Event.where("title = ? and id != ?", @event.title, @event.id).length != 0
      @repeatly = true
    else
      @repeatly = false
    end

    respond_to do |format|
      format.html do
        render partial: 'edit'
      end
    end
  end

  def update
    @event = Event.find(params[:id])
    @rooms = Room.all
    if Event.where("title = ? and id != ?", @event.title, @event.id).length != 0
      @repeatly = true
    else
      @repeatly = false
    end

    add_new_organizers_and_lectors

    old_title = @event.title
    respond_to do |format|
      if @event.update(event_params)
        edit_repeatly_events(old_title) if params.permit(:change)[:change] == "future"
        create_repeatly_events if params.permit(:repeatly).has_key? :repeatly

        format.html { redirect_to request.referrer }
      else
        flash[:notice] = @event.errors['text'].last
        format.html { render partial: 'edit' }
      end
    end
  end

  def destroy
    deleting_event = Event.find(params[:id])
    case params.permit(:value)[:value]
    when "this"
      deleting_event.update(archive: true)
    when "future"
      deleting = Event.where("title = ? and room_id = ? and archive = ? and date >= ?", deleting_event.title, deleting_event.room_id, false, deleting_event.date)
    when "all"
      deleting = Event.where("title = ? and room_id = ? and archive = ?", deleting_event.title, deleting_event.room_id, false)
    end

    if deleting
      deleting.each do |event|
        event.update(archive: true)
      end
    end

    respond_to do |format|
      format.html { redirect_to request.referrer }
    end
  end

  private def event_params
    params.require(:event).permit(:title, :description, :date, :begin_time, :end_time, :room_id, :organizer_id, :lector_id, :user_id)
  end

  private def check_user
    unless current_user.role == "admin" || current_user.id == Event.find(params[:id]).user_id
      redirect_to "users/sign_in", :status => 401
    end
  end

  private def add_new_organizers_and_lectors
    if @event.lector_id == 0
      @event.lector_id = Lector.find_or_create_by(name: params.permit(:new_lector)[:new_lector]).id
    end

    if @event.organizer_id == 0
      @event.organizer_id = Organizer.find_or_create_by(name: params.permit(:new_organizer)[:new_organizer]).id
    end
  end

  private def create_repeatly_events
    case params.permit(:period)[:period]
    when "Каждый день"
      period = 1.day
    when "Каждую неделю"
      period = 7.days
    when "Каждый месяц"
      period = 1.month
    end

    date = DateTime.parse(event_params[:date]) + period
    max_date = Date.parse(params.permit(:max_date)[:max_date])

    while date <= max_date
      e = Event.new(event_params)
      e.date = date
      e.save
      date += period
    end
  end

  private def edit_repeatly_events (old_title)
    Event.where("title = ? and room_id = ? and date > ?", old_title, @event.room_id, @event.date).each do |editable_event|
      editable_event.update(@event.attributes.except("id", "date"))
    end
  end

  private def assist
    respond_to do |format|
      format.html do
        render partial: 'events/assist', locals: { room: Room.find(params[:room_id]) }
      end
    end
  end

end
