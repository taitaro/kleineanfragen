require 'fileutils'

class FetchPapersJob
  class << self
    # enables definition of @state, @scraper in child classes
    attr_accessor :state, :scraper
  end

  def perform(legislative_term) # FIXME
    raise 'State is not defined' unless defined?(self.class.state) && !self.class.state.blank?
    @body = Body.find_by(state: self.class.state)
    raise 'Required body "' + self.class.state + '" not found' if @body.nil?

    raise 'Legislative term is empty' if legislative_term.nil?
    @legislative_term = legislative_term
  end

  def import_new_papers
    raise 'scraper is not defined' unless defined?(self.class.scraper) && !self.class.scraper.blank?
    scraper = self.class.scraper::Overview.new(@legislative_term)
    page = 1
    found_new_paper = false
    begin
      found_new_paper = false
      scraper.scrape(page).each do |item|
        if import_paper(item)
          found_new_paper = true
        end
      end
      page += 1
    end while found_new_paper
  end

  def download_papers
    @papers = Paper.where(body: @body, downloaded_at: nil).limit(50)

    @data_folder = Rails.application.config.paper_storage
    @papers.each do |paper|
      folder = @data_folder.join(@body.folder_name, paper.legislative_term.to_s)
      FileUtils.mkdir_p folder
      filename = paper.reference.to_s + '.pdf'
      path = folder.join(filename)
      `wget -O "#{path}" "#{paper.url}"` # FIXME: use ruby
      if $?.to_i == 0 && File.exists?(path)
        paper.downloaded_at = DateTime.now
        paper.save
      else
        puts "Download failed for Paper #{paper.reference}"
      end
    end
  end

  def extract_text_from_papers
    @papers = Paper.where(body: @body, contents: nil).where.not(downloaded_at: nil)

    @papers.each do |paper|
      puts "Extracting text from [#{paper.reference}] \"#{paper.title}\""
      text = paper.extract_text
      paper.contents = text
      paper.save
    end
  end

  def count_page_numbers
    @papers = Paper.where(body: @body, page_count: nil).where.not(downloaded_at: nil)

    @papers.each do |paper|
      puts "Counting pages in [#{paper.reference}] \"#{paper.title}\""
      count = paper.extract_page_count
      paper.page_count = count
      paper.save
    end
  end
end