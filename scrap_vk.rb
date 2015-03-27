require 'open-uri'
require 'nokogiri'
require 'capybara-webkit'
require 'capybara'
require 'capybara/dsl'


# Params:
# +ARGV[0]+:: login
# +ARGV[1]+:: pass
# +ARGV[2]+:: start scrap from page (user_id or feeds ...)
class ScrapVK
  include Capybara::DSL

  PROTOCOL_PREAMBL = "https://"
  SAVE_FOLDER_NAME = "vk/images/"
  HOST_NAME = "vk.com"


  def initialize
    puts "params: "+ARGV.to_s
    @login = ""
    @pass = ""
    @start_page = "/"
    if (!ARGV.empty?)
      @login = ARGV.shift
      @pass = ARGV.shift
      @start_page += ARGV.shift
    end

    # @session = Capybara::Session.new :webkit
    Capybara.default_driver = :webkit

    begin
      Capybara.register_driver :webkit do |app|
        Capybara::Webkit::Driver.new(app).tap do |driver|
          driver.block_unknown_urls
          driver.allow_url HOST_NAME+"/*"
        end
      end
    end

    Capybara.app_host = PROTOCOL_PREAMBL+HOST_NAME
    visit(@start_page)

    login()
    imgSaver()

  end

  def login
    # puts @session.html
    putsCurrUrl()

    within('form#quick_login_form') do
      fill_in('quick_email', :with => @login)
      fill_in('quick_pass', with: @pass)
    end

    @doc = Nokogiri::HTML.parse(page.html)
    @doc.css('img').each do |i|
      puts i
    end

    button = find('#quick_login_button')
    button.click

  end


  def imgSaver
    system 'mkdir', '-p', SAVE_FOLDER_NAME

    putsCurrUrl()
    @doc = Nokogiri::HTML.parse(page.html)

    @doc.css('img').each do |i|
      saveImgNode(i)
    end

=begin
      images = @doc.css('img')
      i = images.first
      saveImgNode(i)
=end

  end


  def saveImgNode(imgNode)
    puts "-saveImg: "+imgNode.to_s
    src = imgNode['src']
    puts " src: "+src

    if (!src.nil?)
      # img_name = /(?<=\/{1})(\w*.(jpg|png|gif|bmp){1})/.match(src).to_s

      if (!/(#{PROTOCOL_PREAMBL})/.match(src).nil?)
        # uri = /(\/{1}\w*.{1}(jpg|png|gif|bmp){1}$)/.match(src).to_s
        uri = File.basename(src)
        puts " img name: "+uri

        save_as = SAVE_FOLDER_NAME+uri
        puts " save as: "+save_as

        if (!uri.nil? && !uri.empty?)
          File.open(save_as, 'wb') { |f| f.write(open(src).read) }
        end
      else
        puts " !img don't consist http!"
      end

    end
  end

  def putsCurrUrl
    puts "Curr url: "+URI.parse(current_url).to_s
  end

end


=begin
    enter_page.links.each do |link|
      text = link.text.strip
      next unless text.length > 0
      puts text
    end
=end

=begin
    session = Capybara::Session.new(:webkit)
    session.visit "http://www.amberbit.com"

    if session.has_content?("Ruby on Rails web development")
      puts "All shiny, captain!"
    else
      puts ":( no tagline fonud, possibly something's broken"
      exit(-1)
    end
=end

=begin
test = "https://pp.vk.me/c622728/v622728792/23feb/GS3X2bw8DG4.jpg"
n = /(http)/.match(test)
if (!n.nil?)
  m = /(\/{1}\w*.{1}(jpg|png|gif|bmp){1}$)/.match(test)
  puts m.to_s
end
=end

=begin
    all(:css, 'img').each do |image|
      puts image.native.children[1]
    end
=end
# page.has_contest?('')

# current_path.should == "/feed"
=begin
    puts @session.find('#quick_email')
    puts @session.find_field('quick_email')

    @session.within('form#quick_login_form') do
      @session.fill_in('quick_email',  :with => @login)
      @session.fill_in('quick_pass', with: @pass)
      # choose('A Radio Button')
      # check('A Checkbox')
      # uncheck('A Checkbox')
      # attach_file('Image', '/path/to/image.jpg')
      # select('Option', :from => 'Select Box')
      end

      # click_link 'Sign in'
    end
=end