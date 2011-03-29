#!/usr/bin/env ruby
#
# This script demonstrates some Surface palette "special effects".
#
# Usage: ./demo_palette [image]
#
#   If no image is given, palettized.png is used. If the given image
#   has no palette, a grayscale palette will be used.
#
# Controls:
#
#  Escape or Q = quit
#  Space = pause or unpause palette motion
#  Numbers key = change mode
#    1 = original palette, forward rotation
#    2 = rainbow palette, forward rotation
#    3 = ruby-colored wave palette, reverse rotation
#    4 = original palette, shuffle
#

require 'rubygame'
include Rubygame
include Rubygame::Events


class App

  # Set up the App. image_path is an absolute path to the image file
  # to load and display.
  #
  def initialize( image_path )
    setup_surface( image_path )
    setup_screen

    @queue = EventQueue.new{ |q|
      q.enable_new_style_events
    }

    @clock = Clock.new { |c|
      c.enable_tick_events
      c.target_framerate = 50
      c.calibrate
    }

    @original_palette = @surface.palette.colors

    # A block to be called by #update once per frame.
    @update_block = basic_rotation(2.0)

    # Whether #update should call @update_block.
    @active = true

    # Whether #draw should re-blit @surface onto @screen.
    @dirty = true
  end


  # Load the image as a Surface. If the image does not have a palette,
  # creates a new Surface with a palette, then blits the original
  # image to the new Surface to create a palettized version.
  #
  def setup_surface( image_path )
    @surface = Surface.load(image_path)

    unless @surface.palette
      puts( "Image '#{image_path}' has no palette.\n" +
            "Converting to a grayscale palette." )

      orig = @surface

      # Create a new palettized surface with a grayscale palette from
      # [0,0,0] (black) to [255,255,255] (white).
      @surface = Surface.new(orig.size, :depth => 8)
      @surface.palette = (0..255).collect{ |i| [i,i,i] }

      # Blit the original image onto the palettized surface. Each
      # pixel in the original image is converted to the most similar
      # color in the grayscale palette.
      orig.blit(@surface, [0,0])
    end

    # Create a rect determining where on the screen to blit @surface.
    # #setup_screen might move this rect so @surface is blitted in the
    # center of the screen.
    @rect = @surface.make_rect
  end


  # Open the Screen and render a helpful message if TTF support is
  # available. #setup_surface must be run before this.
  #
  def setup_screen
    if defined? Rubygame::TTF
      font_path = File.expand_path("FreeSans.ttf",
                                   File.dirname(__FILE__))

      @font = TTF.new(font_path, 14)

      message = "Controls: space = pause; number keys = change mode"
      text = @font.render(message, true, :white, :black)

      # Make sure the screen is wide enough to fit @surface or the
      # text (plus some padding), whichever is wider.
      width = [@surface.w, text.w+4].max

      @screen = Screen.open([width, @surface.h + text.h])

      # Center the @surface in the center x of the screen.
      @rect.centerx = @screen.make_rect.centerx

      # Center the text in the middle bottom of the screen.
      text_rect = text.make_rect
      text_rect.midbottom = @screen.make_rect.midbottom
      text.blit(@screen, text_rect)
    else
      # No TTF support, no message, much simpler setup.
      @screen = Screen.open(@surface.size)
    end

    @screen.title = "Rubygame Palette Demo"
  end


  # Main game loop. Each frame, it handles input events, updates the
  # palette (see #update), and refreshes the screen (see #draw).
  #
  def go
    catch(:rubygame_quit) do
      loop do

        @queue.each do |event|
          case event
          when KeyPressed
            case event.key
            when :escape, :q
              throw :rubygame_quit
            when :space
              @active = !@active
            when :number_1, :keypad_1;  mode 1
            when :number_2, :keypad_2;  mode 2
            when :number_3, :keypad_3;  mode 3
            when :number_4, :keypad_4;  mode 4
            when :number_5, :keypad_5;  mode 5
            # when :number_6, :keypad_6;  mode 6
            # when :number_7, :keypad_7;  mode 7
            # when :number_8, :keypad_8;  mode 8
            # when :number_9, :keypad_9;  mode 9
            # when :number_0, :keypad_0;  mode 0
            end
          when QuitRequested
            throw :rubygame_quit
          end
        end

        update( @clock.tick )

        draw

      end # loop
    end # catch
  end


  # This method is called once per frame to update the palette effect.
  # @update_block is a block that implements the palette effect logic
  # (see e.g. #basic_rotation). @update_block is passed a ClockTicked
  # event each frame, unless @active is false.
  #
  def update( tick )
    if @active and @update_block
      @update_block.call(tick)
    end
  end


  # Refreshes @screen. If @dirty is true (see #basic_rotation), it
  # blits the @surface onto @screen so that the user can see how the
  # palette has changed.
  #
  def draw
    if @dirty
      @surface.blit( @screen, @rect )
      @dirty = false
    end
    @screen.update()
  end


  # Switch to a new demo mode.
  #
  # 1 = original palette, forward rotation
  # 2 = rainbow palette, forward rotation
  # 3 = ruby-colored wave palette, reverse rotation
  # 4 = original palette, shuffle
  #
  def mode( new_mode )
    case new_mode
    when 1
      @surface.palette = @original_palette
      @update_block = basic_rotation(2.0)
    when 2
      @surface.palette = rainbow_palette(@surface.palette.size)
      @update_block = basic_rotation(2.0)
    when 3
      @surface.palette = wave_palette(@surface.palette.size, 2)
      @update_block = basic_rotation(2.0, -1)
    when 4
      @surface.palette = @original_palette
      @update_block = basic_shuffle(0.3)
    else
      mode 1
    end

    @dirty = true

    nil
  end


  # Returns a palette with colors ranging from hue 0.0 to 1.0.
  def rainbow_palette( ncolors )
    (0...ncolors).collect { |i|
      i = i.to_f / ncolors
      Color.hsl( [i, 1.0, 0.5] )
    }
  end

  # Returns a colored palette oscilating from dark to light.
  # peaks is the number of peaks (light spots) in the palette.
  #
  def wave_palette( ncolors, peaks=1, hue=0.967 )
    (0...ncolors).collect { |i|
      i = i.to_f / ncolors
      value = -Math.cos( i * peaks * Math::PI*2 )*0.5 + 0.5
      Color.hsl( [hue, 0.9, 0.2 + value*0.6] )
    }
  end


  # Returns a block that implements a basic palette rotation, to be
  # used as @update_block (see #update). When @surface's palette is
  # changed, @dirty is set to true (see #draw).
  #
  # period:: How long it takes to rotate through the whole palette.
  # direction:: Which way to rotate (1 or -1).
  #
  def basic_rotation( period=1.0, direction=1 )
    @t = 0
    @t_limit = period.to_f / @surface.palette.size

    Proc.new { |tick|
      @t += tick.seconds
      rotations = 0

      while @t > @t_limit
        @t -= @t_limit
        rotations += direction
      end

      if rotations != 0
        @surface.palette.rotate!(rotations)
        @dirty = true
      end
    }
  end


  # Returns a block that implements a basic palette shuffle, to be
  # used as @update_block (see #update). When @surface's palette is
  # changed, @dirty is set to true (see #draw).
  #
  # delay:: How long to wait before shuffling again.
  #
  def basic_shuffle( delay=1.0 )
    @t = 0

    Proc.new { |tick|
      @t += tick.seconds
      shuffle = false

      while @t > delay
        @t -= delay
        shuffle = true
      end

      if shuffle
        @surface.palette.shuffle!
        @dirty = true
      end
    }
  end

end


# If this file is being executed (rather than 'required'), process
# command line arguments and run the app.
#
if $0 == __FILE__
  if ARGV[0]
    # Image path passed as a command line argument.
    image_path = File.expand_path(ARGV[0], Dir.pwd)
  else
    # No command line arguments, so use the default image.
    puts "You can pass a image to this script to load it."
    image_path = File.expand_path("palettized.png",
                                  File.dirname(__FILE__))
  end

  App.new(image_path).go()
end
