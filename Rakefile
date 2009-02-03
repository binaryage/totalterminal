require 'rake'

ROOT_DIR = File.expand_path('.')
SRC_DIR = File.join(ROOT_DIR, 'src')
XCODE_PROJECT = File.join(SRC_DIR, 'Visor.xcodeproj')
BUILD_DIR = File.join(SRC_DIR, 'build')
BUILD_RELEASE_DIR = File.join(BUILD_DIR, 'Release')
BUILD_RELEASE_PATH = File.join(BUILD_RELEASE_DIR, 'Visor.bundle')
RELEASE_DIR = File.join(ROOT_DIR, 'releases')

# http://kpumuk.info/ruby-on-rails/colorizing-console-ruby-script-output/
begin
  require 'Win32/Console/ANSI' if PLATFORM =~ /win32/
rescue LoadError
  raise 'You must "gem install win32console" to use terminal colors on Windows'
end

def colorize(text, color_code)
  "#{color_code}#{text}\e[0m"
end

def red(text); colorize(text, "\e[31m"); end
def green(text); colorize(text, "\e[32m"); end
def yellow(text); colorize(text, "\e[33m"); end
def blue(text); colorize(text, "\e[34m"); end
def magenta(text); colorize(text, "\e[35m"); end
def azure(text); colorize(text, "\e[36m"); end
def white(text); colorize(text, "\e[37m"); end
def black(text); colorize(text, "\e[30m"); end

def file_color(text); yellow(text); end
def dir_color(text); blue(text); end
def cmd_color(text); azure(text); end

def die(s)
  puts red("Error[#{$?}]: #{s}")
  exit $?
end

def version()
  $version = ENV["version"]||"1.6"
end

def revision()
  $revision = `git rev-parse --short=6 HEAD`.strip
end

def dirty_repo_warning()
  is_clean = `git status`.match(/working directory clean/)
  puts red("Repository is not clean! You should commit all changes before releasing.") unless is_clean
end

desc "opens XCode project"
task :open do 
  `open "#{XCODE_PROJECT}"`
end

desc "builds project"
task :build do
  puts "#{cmd_color('Building')} #{file_color(XCODE_PROJECT)}"
  Dir.chdir(SRC_DIR) do
    `xcodebuild -configuration Release 1>&2`
    die("build failed") unless $?==0
  end
end

desc "prepares release"
task :release do
  puts "#{cmd_color('Checking environment ...')}"
  dirty_repo_warning()
  version()
  revision()
  mkdir_p(RELEASE_DIR) unless File.exists? RELEASE_DIR
  Rake::Task["build"].execute
  result = File.join(RELEASE_DIR, "Visor-#{$version}-#{$revision}.zip");
  puts "#{cmd_color('Zipping')} #{dir_color(result)}"
  Dir.chdir(BUILD_RELEASE_DIR) do
    unless system("zip -r \"#{result}\" Visor.bundle") then puts red('need zip on command line (download http://www.info-zip.org/Zip.html)') end;
  end
  Rake::Task["clean"].execute
end

desc "removes intermediate build files"
task :clean do
  puts "#{cmd_color('Removing')} #{dir_color(BUILD_DIR)}"
  `rm -rf "#{BUILD_DIR}"`
end

task :default => :build