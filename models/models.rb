# Models
# ------

# Package class.
# - Stores package creation.
# - Creates packages using repo objects.
class Package

  include DataMapper::Resource

  property :id, Serial, :key => true
  property :branch, Enum[:dev, :master], :required => true
  property :version, String
  property :published, Boolean, :default => false
  # zip_file, branch_version_uid.zip
  property :zip_file, String
  property :created_at, DateTime
  property :updated_at, DateTime

  # The main pack method.
  # Handles the package creation before saving.
  def pack
    @repo = Repo.new
    unless @repo.clone
      throw :halt
    end
    @repo.checkout(self.branch)
    self.version = @repo.version
    self.zip_file = @repo.zip
    @repo.clean
  end

  def url
    "#{PACKAGES_DIR}/#{self.zip_file}"
  end

  before :destroy do |package|
      system "rm #{PACKAGES_PATH}/#{package.zip_file}"
  end

end

# The repo class.
# Handles git interaction and zipping.
class Repo

  # Constants.
  @@remote_url = "#{GIT_URL}"
  @@packages_path = "#{PACKAGES_PATH}"

  def initialize
    # Used for temp repo folder.
    @random_id = SecureRandom.hex(5)
    @local_url = "#{Dir.pwd}/tmp/#{@random_id}"
    @current_branch = :master
  end

  # Clone remote repo.
  # => true | false
  def clone
    system "git clone #{@@remote_url} #{@local_url}" || false
  end

  # Delete any trace of repo.
  # => true | false
  def clean
    system "rm -rf #{@local_url}" || false
  end

  # Switch branch.
  # (:dev | :master)
  # => true | false
  def checkout(branch)
    if system "cd #{@local_url} && git checkout #{branch} && git pull origin #{branch}"
      @current_branch = branch
    end
  end

  # Get plugin version.
  # => x.x.x
  def version
    # Parse index.php for "Version: "
    index_file = File.read("#{@local_url}/index.php")
    index_file.match(/Version: (.*)Author:/m)[1].strip
  end

  # Zip the plugin.
  # => packages/branch_version_randomid.zip
  def zip
    version = self.version
    zip_file = "#{@current_branch}_#{version}_#{@random_id}.zip"
    minifier = Minifier.new
    minifier.minify_js("#{@local_url}/js")
    minifier.minify_css("#{@local_url}/css")
    transifex = Transifex.new("#{@local_url}/languages/")
    transifex.translate
    # Create new zip.
    if system "cd #{Dir.pwd}/tmp/ && zip -r #{@@packages_path}/#{zip_file} #{@random_id}"
      return zip_file
    end
  end

end

# Minifier Class.
# Handles various minifications and compressions.
class Minifier

  # Minify JS files, non recursive.
  # (folder)
  def minify_js(folder)
    # Select all files within folder.
    Dir.open(folder).each do |source_name|
      source_file = "#{folder}/#{source_name}"
      temp_file = "#{folder}/temp-#{source_name}"
      # Skip if not js.
      next unless (File.extname(source_file) == '.js')
      # Create temporary empty file.
      File.open(temp_file, "w") do |minified_file|
        # Minify file.
        minified_file.write(Uglifier.compile(File.read(source_file)))
      end
      # Delete original file and rename minified to original.
      File.delete(source_file)
      File.rename(temp_file, source_file)
    end
  end

  # Minify CSS files, non recursive.
  # (folder)
  def minify_css(folder)
    # Select all files within folder.
    Dir.open(folder).each do |source_name|
      source_file = "#{folder}/#{source_name}"
      temp_file = "#{folder}/temp-#{source_name}"
      # Skip if not css.
      next unless (File.extname(source_file) == '.css')
      # Create temporary empty file.
      File.open(temp_file, "w") do |minified_file|
        # Minify file.
        sass_engine = Sass::Engine.new(
          File.read(source_file),
          :syntax => :scss,
          :style => :compressed,
          :cache => false
        )
        minified_file.write(sass_engine.render)
      end
      # Delete original file and rename minified to original.
      File.delete(source_file)
      File.rename(temp_file, source_file)
    end
  end

end

# Transifex Class.
# Handles transifex integration
class Transifex

  def initialize(languages_dir)
    @languages_dir = languages_dir
  end
    
  # Remove previous .mo files.
  # => (true | false)
  def reset
    system "rm -rf #{@languages_dir}/*.mo" || false
  end

  # Pull latest .po from transifex.
  # => (true | false)
  def pull
    system "cd #{TRANSIFEX_DIR} && tx pull -a" || false
  end

  # Move latest .po to package languages directory.
  # => (true | false)
  def move
    system "cp #{TRANSIFEX_DIR}/*.po #{@languages_dir}" || false
  end

  # Convert .po to .mo, and remove .po, if successfully converted.
  # => (true | false)
  def convert
    converted = true
    Dir.open(@languages_dir).each do |po_file|
      next unless (File.extname(po_file) == '.po')
      file_name = File.basename(po_file, '.po')
      if system "cd #{@languages_dir} && msgfmt #{file_name}.po -o #{file_name}.mo"
        system "rm #{@languages_dir}/#{po_file}"
      else
        converted = false
      end
    end
    return converted
  end

  def translate
    self.reset and
    self.pull and
    self.move and
    self.convert
  end

end