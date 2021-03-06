# HourReportsController manages the {HourReport} objects by providing a RESTful HTML interface. 
# @author Shen Chen Xu
class HourReportsController < ApplicationController
  before_filter :require_user
  before_filter :fetch_available_tasks, :only => [:index, :new, :create, :edit, :update]
  # GET /hour_reports
  # GET /hour_reports.xml
  def index 
    state_condition = [HourReport::Pending, HourReport::Rejected]
    if params[:all]
      state_condition = false
    else
      if params[:pending]
        state_condition = HourReport::Pending
      elsif params[:rejected]
        state_condition = HourReport::Rejected
      end
      @hour_report = HourReport.new
    end
    conditions = {:user_id => current_user.id}
    conditions[:state] = state_condition if state_condition
    @hour_reports = HourReport.find(:all, :include => {:task => {:project => [:users, :user]}, :user => nil}, :order => "date DESC", :conditions => conditions)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @hour_reports }
    end
  end

  # GET /hour_reports
  # GET /hour_reports.xml
  def all
    @hour_reports = HourReport.find(:all, :conditions => {:user_id => current_user.id })

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @hour_reports }
    end
  end

  # GET /hour_reports/1
  # GET /hour_reports/1.xml
  def show
    @hour_report = HourReport.find(params[:id])
    enforce_view_permission(@hour_report)
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @hour_report }
    end
  end

  # GET /hour_reports/new
  # GET /hour_reports/new.xml
  def new
    @hour_report = HourReport.new
    @hour_report.user_id = current_user.id
    @hour_report.task ||= current_user.projects.last.tasks.first if current_user.projects and current_user.projects.last.tasks
    
    @tasks = Task.find(:all)
    @users = User.find(:all)

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @hour_report }
    end
  end

  # GET /hour_reports/1/edit
  def edit
    @hour_report = HourReport.find(params[:id])
    enforce_update_permission(@hour_report)
    @tasks = Task.find(:all)
    @users = User.find(:all)
    
  end

  # POST /hour_reports
  # POST /hour_reports.xml
  def create
    @hour_report = HourReport.new(params[:hour_report])
    @hour_report.state = HourReport::Pending
    @hour_report.user_id = current_user.id
    enforce_create_permission(@hour_report)
    
    respond_to do |format|
      if @hour_report.save
        flash[:notice] = 'Hour Report was successfully created.'
        format.html { redirect_to(@hour_report) }
        format.xml  { render :xml => @hour_report, :status => :created, :location => @hour_report }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @hour_report.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /hour_reports/1
  # PUT /hour_reports/1.xml
  def update
    @hour_report = HourReport.find(params[:id])
    @hour_report.state = HourReport::Pending

    enforce_update_permission(@hour_report)
    
    respond_to do |format|
      if @hour_report.update_attributes(params[:hour_report])
        flash[:notice] = 'HourReport was successfully updated.'
        format.html { redirect_to(@hour_report) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @hour_report.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /hour_reports/1
  # DELETE /hour_reports/1.xml
  def destroy
    @hour_report = HourReport.find(params[:id])
    @hour_report.destroy
    enforce_destroy_permission(@hour_report)

    respond_to do |format|
      format.html { redirect_to(hour_reports_url) }
      format.xml  { head :ok }
    end
  end

  def approve
    @hour_report = HourReport.find(params[:id])
    @hour_report.state = HourReport::Approved
    enforce_approve_permission(@hour_report)

    respond_to do |format|
      if @hour_report.update_attributes(params[:hour_report])
        flash[:notice] = 'HourReport was successfully approved.'
        format.html { redirect_to(:back) }
        #format.html { redirect_to(@hour_report) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @hour_report.errors, :status => :unprocessable_entity }
      end
    end
        end

  def reject
    @hour_report = HourReport.find(params[:id])
    @hour_report.state = HourReport::Rejected
    enforce_reject_permission(@hour_report)

    respond_to do |format|
      if @hour_report.update_attributes(params[:hour_report])
        flash[:notice] = 'HourReport was successfully rejected.'
        format.html { redirect_to(:back) }
        #format.html { redirect_to(@hour_report) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @hour_report.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  private
  
  def fetch_available_tasks
    @available_tasks = current_user.projects.inject([]) { |array, project| array.concat(project.tasks) }
  end
end
