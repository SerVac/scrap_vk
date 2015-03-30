require 'open-uri'
require 'nokogiri'
require 'mechanize'
require 'capybara-webkit'
require 'capybara'
require 'capybara/dsl'


# Params:
# +ARGV[0]+:: scrap album page (album...)
class ScrapVK
  include Capybara::DSL

  PROTOCOL_PREAMBL = "https://"
  HOST_NAME = "vk.com"

  def initialize
    puts "params: "+ARGV.to_s
    @save_folder_name = "vk/images"
    # @login = ""
    # @pass = ""
    @start_page = "/"
    if (!ARGV.empty?)
      # @login = ARGV.shift
      # @pass = ARGV.shift
      @start_page += ARGV.shift
    end

    @save_folder_name += @start_page +"/"
    puts "save folder: " + @save_folder_name

    begin
      # @session = Capybara::Session.new :webkit
      Capybara.register_driver :webkit do |app|
        Capybara::Webkit::Driver.new(app).tap do |driver|
          driver.block_unknown_urls
          driver.allow_url HOST_NAME+"/*"
          driver.allow_url "vk.me/*"
        end
      end
      Capybara.default_driver = :webkit

    end

    Capybara.app_host = PROTOCOL_PREAMBL+HOST_NAME
    visit(@start_page)

    # login()
    imgSaver()

  end


  def login
    putsCurrUrl()

    within('form#quick_login_form') do
      fill_in('quick_email', :with => @login)
      fill_in('quick_pass', with: @pass)
    end

    button = find('#quick_login_button')
    button.click()

  end

  def imgSaver
    system 'mkdir', '-p', @save_folder_name

    putsCurrUrl()
    img_total = find('.summary').text
    img_total = /.(\d*)./.match(img_total)[0].to_i
    puts " In album '"+img_total.to_s+"' images"

    img_start = first(:css, 'div.photo_row > a')
    img_start.click()

    img_list = []
    ignore_list = []

    css_photo = '#pv_photo'
    css_origin = '#pv_open_original'
    file_name = ''

    count_total = 0
    count_retry = 0

    begin
      puts ""
      puts "--next"

      imgs_box = find('div#pv_box')
      if (imgs_box.assert_selector(css_photo))

        img_link = imgs_box.find(css_photo)
        puts img_link['href']

        begin
          count_total += 1
          if (imgs_box.assert_selector(css_origin))
            file_name = saveByLink(imgs_box.find(css_origin)['href'])
          else
            file_name = saveByImgNode(img_link.find('img'))
          end

          img_list.push(file_name)
          puts " file added: "+file_name

          count_retry = 0
          img_link.click()

        rescue StandardError => e
          if (!ignore_list.include?(@curr_file_name))
            count_retry = 0
            ignore_list.push(@curr_file_name)
            puts " :ignore "+ignore_list.size.to_s
          else
            count_retry += 1
            puts " :retry "+count_retry.to_s
            sleep 1
            if (count_retry > 1)
              puts " Something wrong! Retry break!"
              break
            end
          end

          img_link.click()

        end

      else
        puts "break !"
        break
      end

    end while count_total <= img_total

    puts img_list.to_s
    puts "- The '"+img_list.size.to_s+"' images from album '"+@start_page+"' is saved! -"


  end

  def saveByImgNode(img_node)
    puts "-Save img: "+img_node.to_s
    return saveByLink(img_node['src'])
  end

  def saveByLink(link)
    puts "-Save file by link: "+link
    file_name = nil
    if (!link.nil?)
      if (!/(#{PROTOCOL_PREAMBL})/.match(link).nil?)
        file_name = File.basename(link)
        @curr_file_name = file_name
        puts " file name: "+file_name

        save_as = @save_folder_name+file_name
        if (!File.file?(save_as))
          File.open(save_as, 'wb') { |f| f.write(open(link).read) }
          puts " file save path: "+save_as
          return file_name.to_s
        end

      else
        puts " :save link is not consist 'http' !"
      end
    else
      " :save link is empty!"
    end

    raise " :file '"+file_name+"' is exist!"
    return nil
  end

  def putsCurrUrl
    puts "Curr url: "+URI.parse(current_url).to_s
  end

end
