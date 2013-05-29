# Configuration
# -------------

# Set local sqlite DB.
DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/local.db")

# Enable Sessions for Rack Flash Messages.
enable :sessions

# Global settings.
GIT_URL = ENV['GIT_URL']
PACKAGES_DIR = 'packages'
PACKAGES_PATH = "#{Dir.pwd}/public/#{PACKAGES_DIR}"
TRANSIFEX_DIR = "#{Dir.pwd}/tmp/transifex"


# Helpers
# -------

helpers do
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end
  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == [ENV['USERNAME'], ENV['PASSWORD']]
  end
end


# Models
# ------

require "#{Dir.pwd}/models/models.rb"


# Datamapper Commands
# -------------------

DataMapper.finalize
# DataMapper.auto_migrate!
DataMapper.auto_upgrade!


# Routes
# ------

get	"/" do
	protected!
	@devs = Package.all(:branch => :dev).reverse
	@masters = Package.all(:branch => :master).reverse
	@last_dev = @devs.first
	@last_master = @masters.first
	erb :home
end

post "/package" do
	protected!
	package = Package.new(params[:package])
	# Find old, not public packages.
	not_public = Package.all(
			:published => false,
			:branch => package.branch
		)
	# Destroy them.
	not_public.destroy
	# Create new package.
	package.pack
	if package.save
		redirect "/"
	else
		flash[:error] = package.errors.full_messages.join("<br />")
		redirect "/"
	end
end

post "/publish" do
	protected!
	package = Package.get(params[:id].to_i)
	previous_public = Package.all(
		:branch => package.branch,
		:published => true
	)
	previous_public.update(:published => false)
	if package.update(:published => true)
		redirect "/"
	else
		flash[:error] = package.errors.full_messages.join("<br />")
		redirect "/"
	end
end

# API

# params[:branch] (dev | master)
get "/release/check" do
	# Get published package
	published_package = Package.first(
		:branch => params[:branch],
		:published => true
	)
	if published_package
		"#{published_package.version}"
	end
end

# params[:branch] (dev | master)
get "/release/zip" do
	# Get published package
	published_package = Package.first(
		:branch => params[:branch],
		:published => true
	)
	if published_package
		file = "#{Dir.pwd}/public/#{published_package.url}"
		send_file(file, :filename => published_package.zip_file)
	end
end
