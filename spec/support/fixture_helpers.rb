# FixtureLoops help us by looping over a folder to read fixture fields
module FixtureHelpers
  def load_fixture_file(path)
    File.read(path)
  end

  def yield_files_in_fixtures_folder(path, &block)
    dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'fixtures', path))

    Dir[dir].entries.sort.each do |file_path|
      file = load_fixture_file(file_path)
      block.call(file_path.split("/").last, file)
    end
  end
  alias each_fixture yield_files_in_fixtures_folder

  def metadata_file
    file_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'fixtures/corpus/metadata_expected.yaml'))
    data = load_fixture_file(file_path)
    YAML.load(data)
  end

  def readerdoc_file
    file_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'fixtures/corpus/metadata_expected.yaml'))
    data = load_fixture_file(file_path)
    YAML.load(data)
  end
end

# Loads a fixture to get the data from it directly
module FixtureLoader
  def load_fixture_file(path)
    File.read(path)
  end

  def load_from_fixture_folder(relative_path)
    file = File.expand_path(File.join(File.dirname(__FILE__), '../fixtures/', relative_path))
    load_fixture_file(file)
  end
end

RSpec.configure do |config|
  config.include FixtureLoader
  config.extend FixtureHelpers
end
