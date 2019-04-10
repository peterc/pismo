# Tools to check the author hash and results to make sure we're finding the
# same, right stuff.
module AuthorHelpers
  def expect_to_have_at_least_one_author(helper)
    expect(helper.authors.count).to be > 0
  end

  def expect_to_find_the_same_author_results(helper, hsh)
    expected_results = hsh[:results]
    found_results = helper.authors
    expect(found_results.count).to be >= expected_results.count

    expected_types = expected_results.map { |profile| profile[:type] }.sort
    found_types = found_results.map { |profile| profile[:type] }.sort
    expect(found_types).to include *expected_types

    expected_names = expected_results.map { |profile| profile[:name] }.sort
    found_names = found_results.map { |profile| profile[:name] }.sort
    expect(found_names).to include *expected_names

    expected_urls = expected_results.map { |profile| profile[:url] }.sort
    found_urls = found_results.map { |profile| profile[:url] }.sort
    expect(found_urls).to include *expected_urls
  end
end

RSpec.configure do |config|
  config.include AuthorHelpers
end
