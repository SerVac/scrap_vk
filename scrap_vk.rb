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
      #{@start_page} += ARGV.shift
    end

    @start_page = "/album19839792_000"

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

    button = find('#quick_login_button')
    button.click()

  end

  def imgSaver
    system 'mkdir', '-p', SAVE_FOLDER_NAME

    img_total = find('.summary').text
    img_total = /\s(\d*)\s/.match(img_total)[0].to_i
    puts "num= "+img_total.to_s

    img_start = first(:css, 'div.photo_row > a')
    img_start.click()

    img_list = []
    ignore_list = []
    css_photo = 'a#pv_photo'
    css_origin = 'a#pv_open_original'
    file_name = ''

    count_retry = 0
    begin
      puts ""
      puts "--next"

      imgs_box = find('div#pv_box')
      if (imgs_box.assert_selector(css_photo))

        img_link = imgs_box.find(css_photo)
        puts img_link['href']

        begin
          if (imgs_box.assert_selector(css_origin))
            file_name = saveByLink(imgs_box.find(css_origin)['href'])
          else
            file_name = saveByImgNode(img_link.find('img'))
          end
          img_list.push(file_name)
          puts " file added: "+file_name
          img_link.click()
          puts " clicked"

          count_retry=0

        rescue StandardError => e
          # file_name = /(?<=\({1})(.+)/.match(e.to_s).to_s
          # puts " error fname= "+@curr_file_name
          if (!ignore_list.include?(@curr_file_name))
            ignore_list.push(@curr_file_name)
            puts " :ignore"
          else
            count_retry+=1
            puts " :retry "+count_retry.to_s
            if (count_retry > 3)
              count_retry = 0
              puts " :clear "+count_retry.to_s
              puts " :break"
              break
            end
          end

          img_link.click()
          sleep 2
        end

      else
        puts "break !"
        break
      end

    end while img_list.size < img_total
    puts img_list.to_s
    puts "- the '"+img_list.size.to_s+"' images from album are '"+@start_page+"' saved! -"

=begin
    img_total = find('.summary').text
    img_total = /\s(\d*)\s/.match(img_total)[0].to_i
    # puts "num= "+img_total.to_s

    img_pool = []
    @doc = Nokogiri::HTML.parse(page.html)
    @doc.css('div.photo_row').each do |i|
      img_pool.push(i)
    end
    puts img_pool.count
    i = img_pool[0]
    find('#'+i['id']).click()
=end

  end

  def saveByImgNode(img_node)
    puts "-Save img: "+img_node.to_s
    return saveByLink(img_node['src'])
    # img_name = /(?<=\/{1})(\w*.(jpg|png|gif|bmp){1})/.match(src).to_s
  end

  def saveByLink(link)
    puts "-Save file by link: "+link
    file_name = nil
    if (!link.nil?)
      if (!/(#{PROTOCOL_PREAMBL})/.match(link).nil?)
        file_name = File.basename(link)
        @curr_file_name = file_name
        puts " file name: "+file_name

        save_as = SAVE_FOLDER_NAME+file_name
        if (!File.file?(save_as))
          File.open(save_as, 'wb') { |f| f.write(open(link).read) }
          puts " file save as path: "+save_as
          return file_name.to_s
        end

        puts " :file '"+file_name+"' is exist !"
      else
        puts " :save link is not consist 'http' !"
      end
    else
      " :save link is empty!"
    end


    # rescue SystemCallError
    #   " :file is exist" if file_name.nil?

    raise " :file ("+file_name+") is exist"
    return nil
  end

  def putsCurrUrl
    puts "Curr url: "+URI.parse(current_url).to_s
  end

end
