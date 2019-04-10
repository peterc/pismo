# FixtureLoops help us by looping over a folder to read fixture fields
module FixtureHelpers
  def load_fixture_file(path)
    File.read(path)
  end

  def write_updated_fixture_with_results(hsh)
    write_fixture_file(file_path, hsh.to_yaml)
  end

  def write_fixture_file(file_path, data)
    File.open(file_path, 'w') { |file| file.write() }
  end

  def yield_files_in_fixtures_folder(path, &block)
    dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'fixtures', path))

    Dir[dir].entries.sort.each_with_index do |file_path, indx|
      next if file_path == '..' || file_path == '.'

      file = load_fixture_file(file_path)
      block.call(file_path, file_path.split("/").last, file)
    end
  end
  alias each_fixture yield_files_in_fixtures_folder

  def get_fixture(file_path)
    full_file_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'fixtures', file_path))
    data = load_fixture_file(full_file_path)
    return file_path, full_file_path, data
  end

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

  def get_fixture(file_path)
    full_file_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'fixtures', file_path))
    data = load_fixture_file(full_file_path)
    return file_path, full_file_path, data
  end

  def get_yaml_fixture(file_path)
    full_file_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'fixtures', file_path))
    data = load_fixture_file(full_file_path)
    data = YAML.load(data)
    return file_path, full_file_path, data
  end

  def load_from_fixture_folder(relative_path)
    file = File.expand_path(File.join(File.dirname(__FILE__), '../fixtures/', relative_path))
    load_fixture_file(file)
  end

  def write_fixture_file(file_path, data)
    File.open(file_path, 'w') { |file| file.write(data) }
  end
end

RSpec.configure do |config|
  config.include FixtureLoader
  config.extend FixtureHelpers
end
