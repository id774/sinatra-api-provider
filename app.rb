# -*- coding: utf-8 -*-
require 'rubygems'
require 'sinatra/base'
require 'haml'
require 'json'
require 'date'
require 'time'
require 'mongo'

class SinatraApiProvider < Sinatra::Base
  #require './helpers/render_partial'

  def initialize(app = nil, params = {})
    super(app)
    @mongo    = Mongo::Connection.new('localhost', 27017)
    @db       = @mongo.db('houseapi')
    @root = Sinatra::Application.environment == :production ? '/api/' : '/'
  end

  def logger
    env['app.logger'] || env['rack.logger']
  end

  def period_parser
    if @params['period']
      case @params['period']
        when "day"
          period = 1
        when "week"
          period = 7
        when "month"
          period = 30
        else
          period = 0
      end
      from = Time.parse((Date.today - period).strftime("%Y%m%d"))
      from += from.utc_offset
      from = from.utc
      @query_params[:time] = {"$gt" => from}
    end
  end

  def time_parser
    if @params['from']
      begin
        from = Time.strptime(@params['from'], "%Y%m%d%H%M%S")
        from += from.utc_offset
        from = from.utc
      rescue ArgumentError
        from = nil
      end
    else
      from = nil
    end

    if @params['to']
      begin
        to = Time.strptime(@params['to'], "%Y%m%d%H%M%S")
        to += to.utc_offset
        to = to.utc
      rescue ArgumentError
        to = nil
      end
    else
      to = nil
    end

    if from and to
      @query_params[:time] = {"$gt" => from , "$lt" => to}
    end
  end

  def limit_parser
    if @params['limit'] == 0
      @limit_params[:limit] = nil
    elsif @params['limit']
      @limit_params[:limit] = @params['limit'].to_i
    end
  end

  def sort_parser
    if @params['sort'] == "asc"
      @sort_params[:time] = :asc
    end
  end

  def finder
    @query_params = {}
    @limit_params = {:limit => 1}
    @sort_params = {:time => :desc}

    period_parser
    time_parser
    limit_parser
    sort_parser

    @coll.find(@query_params, @limit_params).sort(@sort_params)
  end

  def query(coll_name)
    @coll = @db.collection(coll_name)
    @params = Rack::Utils.parse_query(@env['rack.request.query_string'])
    finder.to_a
  end

  # Root Index
  get '/' do
    haml :index
  end

  # Generic Routing
  get '/:tag_h/:tag_f' do
    content_type :json, :charset => 'utf-8'
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "POST"
    result = query([@params[:tag_h], @params[:tag_f]].join("."))
    result.length == 1 ? result.last.to_json : result.to_json
  end

  get '/:tag_h/:tag_m/:tag_f' do
    content_type :json, :charset => 'utf-8'
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "POST"
    result = query([@params[:tag_h], @params[:tag_m], @params[:tag_f]].join("."))
    result.length == 1 ? result.last.to_json : result.to_json
  end

  get '/:tag_1/:tag_2/:tag_3/:tag_4' do
    content_type :json, :charset => 'utf-8'
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "POST"
    result = query([@params[:tag_1], @params[:tag_2], @params[:tag_3], @params[:tag_4]].join("."))
    result.length == 1 ? result.last.to_json : result.to_json
  end

  run! if app_file == $0
end
