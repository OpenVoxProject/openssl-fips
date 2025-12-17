class Version
  attr_reader :date, :x, :raw

  def initialize(value)
    @raw = value

    if (m = value.match(%r{\A(?<date>\d{4}[-|.]\d{2}[-|.]\d{2})[-|.](?<x>\d+)\z}))
      @date = m['date']
      @x = m['x'].to_i
    else
      @date = nil
      @x = 1
    end
  end

  def self.load_from_changelog
    changelog = File.expand_path('../CHANGELOG.md', __dir__)
    version = File.read(changelog).match(/^## \[([^\]]+)\]/) { |match| match[1] }
    version = version.gsub('-', '.')
    new(version)
  rescue Errno::ENOENT
    new('')
  end

  def to_s
    if malformed?
      raw
    else
      "#{date}.#{x}"
    end
  end

  def next!
    if date == today
      @x += 1
    else
      @date = today
      @x = 1
    end

    self
  end

  private

  def malformed?
    date.nil?
  end

  def today
    Time.now.strftime('%Y.%m.%d')
  end
end

desc 'Set the full version of the project'
task 'vox:version:bump:full' do
  puts 'This project use the current date as version number.  No bump needed.'
end

desc 'Get the current version of the project'
task 'vox:version:current' do
  puts Version.load_from_changelog
end

desc 'Get the next version of the project'
task 'vox:version:next' do
  puts Version.load_from_changelog.next!
end

# rubocop:disable Rake/DuplicateTask
begin
  gem 'github_changelog_generator'
rescue Gem::LoadError
  task :changelog, [:future_release] do
    abort('Run `bundle install --with release` to install the `github_changelog_generator` gem.')
  end
else
  desc 'Generate/update CHANGELOG.md from GitHub issues/PRs'
  task :changelog, [:future_release] do |_, args|
    future_release = args[:future_release] or abort 'You must provide the future release version, e.g. rake "changelog[2025.02.12.1]"'

    header = <<~HEADER.chomp
      # Changelog
      All notable changes to this project will be documented in this file.
    HEADER

    changelog_path = File.expand_path('../CHANGELOG.md', __dir__)

    cmd = %W[
      bundle exec github_changelog_generator
      --user openvoxproject
      --project openssl-fips
      --exclude-labels dependencies,duplicate,question,invalid,wontfix,wont-fix,modulesync,skip-changelog
      --future-release #{future_release}
      --header '#{header}'
    ]

    # Append to existing changelog to preserve additional content
    if File.exist?(changelog_path)
      cmd << '--base CHANGELOG.md'
    else
      cmd << '--since-tag' << '202305040'
    end

    sh cmd.join(' ')
  end
end

desc 'Prepare the changelog for a new release'
task 'release:prepare' do
  ver = Version.load_from_changelog.next!.to_s
  puts "Preparing release #{ver}"
  Rake::Task[:changelog].invoke(ver)
  Rake::Task['release:changelog_components'].invoke(ver)
end
