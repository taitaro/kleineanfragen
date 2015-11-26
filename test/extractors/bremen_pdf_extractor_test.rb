require 'test_helper'

class BremenPDFExtractorTest < ActiveSupport::TestCase
  PREFIX = "9. Letzte Frage?\n\n"
  SUFFIX = "\n\n\n— 2 —\n\n\nD a z u\n\nAntwort des Senats vom"

  def paper_with_contents(contents)
    paper_with_contents_and_title(contents, 'some title')
  end

  def paper_with_contents_and_title(contents, title)
    Struct.new(:contents, :doctype, :title).new(contents, Paper::DOCTYPE_MINOR_INTERPELLATION, title)
  end

  test 'four people, one party' do
    paper = paper_with_contents(
      PREFIX + "Björn Fecker, Dirk Schmidtmann, Dr. Maike Schaefer,\n" +
      'Dr. Matthias Güldner und Fraktion Bündnis 90/Die Grünen' + SUFFIX)

    originators = BremenPDFExtractor.new(paper).extract_originators

    assert_equal 4, originators[:people].size
    assert_equal 'Björn Fecker', originators[:people].first
    assert_equal 'Dirk Schmidtmann', originators[:people].second
    assert_equal 'Dr. Maike Schaefer', originators[:people].third
    assert_equal 'Dr. Matthias Güldner', originators[:people].fourth
  end

  test 'two groups, six people, two parties' do
    paper = paper_with_contents(
      PREFIX + "Björn Fecker, Dirk Schmidtmann, Dr. Maike Schaefer,\n" +
      "Dr. Matthias Güldner und Fraktion Bündnis 90/Die Grünen\n\n" +
      "Sükrü Senkal,\nBjörn Tschöpe und Fraktion der SPD" + SUFFIX)

    originators = BremenPDFExtractor.new(paper).extract_originators

    assert_equal 6, originators[:people].size
    assert_equal 'Björn Fecker', originators[:people].first
    assert_equal 'Dirk Schmidtmann', originators[:people].second
    assert_equal 'Dr. Maike Schaefer', originators[:people].third
    assert_equal 'Dr. Matthias Güldner', originators[:people].fourth
    assert_equal 'Sükrü Senkal', originators[:people].fifth
    assert_equal 'Björn Tschöpe', originators[:people][5]
  end

  test 'factions' do
    paper = paper_with_contents_and_title("Antwort des Senats auf die Kleine Anfrage der Fraktion der SPD und Fraktion DIE LINKE\n\n\n\n\nSituation des ttz Bremerhaven\n\n\nAntwort des Senats\n\nauf die Kleine Anfrage der Fraktion der SPD und Fraktion DIE LINKE\n\nvom 9. September 2015\n\n„Situation des ttz Bremerhaven“\n\nDie Fraktion der SPD  und Fraktion DIE LINKEhat folgende Kleine Anfrage an den Senat", 'Situation des ttz Bremerhaven')
    originators = BremenPDFExtractor.new(paper).extract_originators
    assert_not_nil originators
    assert_not_nil originators[:parties]
    assert_equal 2, originators[:parties].size
    assert_equal 'SPD', originators[:parties].first
    assert_equal 'DIE LINKE', originators[:parties].second
  end
end