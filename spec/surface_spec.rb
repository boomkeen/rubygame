
require 'rubygame'
include Rubygame


samples_dir = File.join( File.dirname(__FILE__), "..", "samples", "")
test_dir = File.join( File.dirname(__FILE__), "" )

test_image = test_dir + "image.png"
test_image_8bit = test_dir + "image_8bit.png"
not_image = test_dir + "short.ogg"
panda = samples_dir + "panda.png"
dne = test_dir + "does_not_exist.png"



describe Surface, "(creation)" do
  before(:each) do
    Rubygame.init()
    @screen = Screen.new([100,100])
  end

  after(:each) do
    Rubygame.quit()
  end

  it "should raise TypeError when #new size is not an Array" do
    lambda {
      Surface.new("not an array")
    }.should raise_error(TypeError)
  end

  it "should raise TypeError when #new size is an Array of non-Numerics" do
    lambda {
      Surface.new(["not", "numerics"])
    }.should raise_error(TypeError)
  end

  it "should raise TypeError when #new size is too short" do
    lambda {
      Surface.new([1])
    }.should raise_error(TypeError)
  end


  context "with :alpha option" do

    context "with no :depth option" do
      it "should have depth 32" do
        surface = Surface.new([10,10], :alpha => true)
        surface.depth.should == 32
      end

      it "should not emit a warning" do
        Kernel.should_not_receive(:warn)
        surface = Surface.new([10,10], :alpha => true)
      end
    end

    context "with :depth => 0" do
      it "should have depth 32" do
        surface = Surface.new([10,10], :alpha => true, :depth => 0)
        surface.depth.should == 32
      end

      it "should not emit a warning" do
        Kernel.should_not_receive(:warn)
        surface = Surface.new([10,10], :alpha => true, :depth => 0)
      end
    end

    context "with :depth => 32" do
      it "should have depth 32" do
        surface = Surface.new([10,10], :alpha => true, :depth => 32)
        surface.depth.should == 32
      end

      it "should not emit a warning" do
        Kernel.should_not_receive(:warn)
        surface = Surface.new([10,10], :alpha => true, :depth => 32)
      end
    end

    [8, 15, 16, 24].each { |d|
      context "with :depth => #{d}" do
        it "should have depth 32" do
          # Don't want the warning text mucking up rspec output
          Kernel.stub(:warn)

          surface = Surface.new([10,10], :alpha => true, :depth => d)
          surface.depth.should == 32
        end

        it "should emit a warning" do
          Kernel.should_receive(:warn).
            with("WARNING: Cannot create a #{d}-bit Surface with " +
                 "an alpha channel. Using depth 32 instead.")
          surface = Surface.new([10,10], :alpha => true, :depth => d)
        end
      end
    }

  end


  context "with :opacity option" do
    it "should set the opacity" do
      @surface = Surface.new([10,10], :opacity => 0.5)
      @surface.opacity.should eql( 0.5 )
    end

    it "should clamp floats less than 0.0" do
      @surface = Surface.new([10,10], :opacity => -1.0)
      @surface.opacity.should eql( 0.0 )
    end

    it "should clamp floats greater than 1.0" do
      @surface = Surface.new([10,10], :opacity => 2.0)
      @surface.opacity.should eql( 1.0 )
    end

    it "should convert integers to floats" do
      @surface = Surface.new([10,10], :opacity => -1)
      @surface.opacity.should eql( 0.0 )
      @surface = Surface.new([10,10], :opacity => 0)
      @surface.opacity.should eql( 0.0 )
      @surface = Surface.new([10,10], :opacity => 1)
      @surface.opacity.should eql( 1.0 )
      @surface = Surface.new([10,10], :opacity => 2)
      @surface.opacity.should eql( 1.0 )
    end

    invalid_args = {
      "true"        => true,
      "a symbol"    => :symbol,
      "an array"    => [1.0],
      "a hash"      => {1=>2},
      "some object" => Object.new,
    }

    invalid_args.each do |thing, arg|
      it "should fail when given #{thing}" do
        expect{ Surface.new([10,10], :opacity => arg) }.to raise_error
      end
    end
  end


  context "with :colorkey option" do
    it "should set the colorkey" do
      surface = Surface.new([10,10], :colorkey => [1,2,3])
      surface.colorkey.should == [1,2,3]
    end

    it "should accept a [R,G,B] array" do
      surface = Surface.new([10,10], :colorkey => [135, 206, 235])
      surface.colorkey.should == [135, 206, 235]
    end

    it "should accept a [R,G,B,A] array but ignore alpha" do
      surface = Surface.new([10,10], :colorkey => [135, 206, 235, 128])
      surface.colorkey.should == [135, 206, 235]
    end

    it "should accept a color name symbol" do
      surface = Surface.new([10,10], :colorkey => :sky_blue)
      surface.colorkey.should == [135, 206, 235]
    end

    it "should accept a color name string" do
      surface = Surface.new([10,10], :colorkey => "sky_blue")
      surface.colorkey.should == [135, 206, 235]
    end

    it "should accept a hex color string" do
      surface = Surface.new([10,10], :colorkey => "#87ceeb")
      surface.colorkey.should == [135, 206, 235]
    end

    it "should accept a Color" do
      surface = Surface.new([10,10], :colorkey => Rubygame::Color[:sky_blue])
      surface.colorkey.should == [135, 206, 235]
    end

    it "should accept nil" do
      surface = Surface.new([10,10], :colorkey => nil)
      surface.colorkey.should be_nil
    end

    invalid_args = {
      "true"          => true,
      "false"         => false,
      "a short array" => [1.0],
      "a hash"        => {1=>2},
      "some object"   => Object.new,
    }

    invalid_args.each do |thing, arg|
      it "should fail when given #{thing}" do
        expect{Surface.new([10,10], :colorkey => arg)}.to raise_error
      end
    end
  end

end



describe Surface, "(loading)" do
  before :each do
    unless( Rubygame::VERSIONS[:sdl_image] )
      raise "Can't test image loading, no SDL_image installed."
    end
  end

  it "should load image to a new Surface" do
    surface = Surface.load( test_image )
  end

  it "should raise an error if file is not an image" do
    lambda{ Surface.load( not_image ) }.should raise_error( SDLError )
  end

  it "should raise an error if file doesn't exist" do
    lambda{ Surface.load( dne ) }.should raise_error( SDLError )
  end
end


describe Surface, "(loading from string)" do
  before :each do
    unless( Rubygame::VERSIONS[:sdl_image] )
      raise "Can't test image loading, no SDL_image installed."
    end

    @data = "\x42\x4d\x3a\x00\x00\x00\x00\x00"+
            "\x00\x00\x36\x00\x00\x00\x28\x00"+
            "\x00\x00\x01\x00\x00\x00\x01\x00"+
            "\x00\x00\x01\x00\x18\x00\x00\x00"+
            "\x00\x00\x04\x00\x00\x00\x13\x0b"+
            "\x00\x00\x13\x0b\x00\x00\x00\x00"+
            "\x00\x00\x00\x00\x00\x00\x00\x00"+
            "\xff\x00"
  end
  
  it "should be able to load from string" do
    surf = Surface.load_from_string(@data)
    surf.get_at(0,0).should == [255,0,0,255]
  end
  
  it "should be able to load from string (typed)" do
    surf = Surface.load_from_string(@data,"BMP")
    surf.get_at(0,0).should == [255,0,0,255]
  end
end


describe Surface, "(marshalling)" do

  before :each do
    @surf = Rubygame::Surface.new([10,20], :depth => 32, :alpha => true)
    @surf.set_at([0,0], [12,34,56,78])
    @surf.set_at([9,9], [90,12,34,56])
    @surf.colorkey = [34,23,12]
    @surf.opacity = 0.123
    @surf.clip = [4,3,2,1]
  end

  it "should support Marshal.dump" do
    lambda { Marshal.dump(@surf) }.should_not raise_error
  end

  it "should support Marshal.load" do
    lambda { Marshal.load( Marshal.dump(@surf) ) }.should_not raise_error
  end

  it "should preserve size" do
    surf2 = Marshal.load( Marshal.dump(@surf) )
    surf2.size.should == [10,20]
  end

  it "should preserve depth" do
    surf2 = Marshal.load( Marshal.dump(@surf) )
    surf2.depth.should == 32
  end

  it "should preserve flags" do
    surf2 = Marshal.load( Marshal.dump(@surf) )
    surf2.flags.should == @surf.flags
  end

  it "should preserve pixel data" do
    surf2 = Marshal.load( Marshal.dump(@surf) )
    surf2.get_at([0,0]).should == [12,34,56,78]
    surf2.get_at([9,9]).should == [90,12,34,56]
  end

  it "should preserve colorkey" do
    surf2 = Marshal.load( Marshal.dump(@surf) )
    surf2.colorkey.should == [34,23,12]
  end

  it "should preserve opacity" do
    surf2 = Marshal.load( Marshal.dump(@surf) )
    surf2.opacity.should == 0.123
  end

  it "should preserve palette" do
    surf = Surface.new([10,20], :depth => 2)
    surf.palette = [[0,1,2], [3,4,5], [6,7,8], [9,10,11]]
    surf2 = Marshal.load( Marshal.dump(surf) )
    surf2.palette.colors.should ==
      [Color.rgb255([0,1,2]), Color.rgb255([3,4,5]),
       Color.rgb255([6,7,8]), Color.rgb255([9,10,11])]
  end

  it "should preserve clip" do
    surf2 = Marshal.load( Marshal.dump(@surf) )
    surf2.clip.should == Rubygame::Rect.new(4,3,2,1)
  end

  it "should preserve taint status" do
    @surf.taint
    surf2 = Marshal.load( Marshal.dump(@surf) )
    surf2.should be_tainted
  end

  it "should preserve frozen status" do
    @surf.freeze
    surf2 = Marshal.load( Marshal.dump(@surf) )
    surf2.should be_frozen
  end

end


describe Surface, "(named resource)" do
  before :each do
    Surface.autoload_dirs = [samples_dir]
  end

  after :each do
    Surface.autoload_dirs = []
    Surface.instance_eval { @resources = {} }
  end

  it "should include NamedResource" do
    Surface.included_modules.should include(NamedResource)
  end

  it "should respond to :[]" do
    Surface.should respond_to(:[])
  end

  it "should respond to :[]=" do
    Surface.should respond_to(:[]=)
  end

  it "should allow setting resources" do
    s = Surface.load(panda)
    Surface["panda"] = s
    Surface["panda"].should == s
  end

  it "should reject non-Surface resources" do
    lambda { Surface["foo"] = "bar" }.should raise_error(TypeError)
  end

  it "should autoload images as Surface instances" do
    unless( Rubygame::VERSIONS[:sdl_image] )
      raise "Can't test image loading, no SDL_image installed."
    end

    Surface["panda.png"].should be_instance_of(Surface)
  end

  it "should return nil for nonexisting files" do
    unless( Rubygame::VERSIONS[:sdl_image] )
      raise "Can't test image loading, no SDL_image installed."
    end

    Surface["foobar.png"].should be_nil
  end

  it "should set names of autoload Surfaces" do
    unless( Rubygame::VERSIONS[:sdl_image] )
      raise "Can't test image loading, no SDL_image installed."
    end

    Surface["panda.png"].name.should == "panda.png"
  end
end



describe Surface, "(blit)" do
  before(:each) do
    Rubygame.init()
    @screen = Screen.new([100,100])
    @surface = Surface.new([100,100])
  end

  after(:each) do
    Rubygame.quit
  end

  it "should raise TypeError when #blit target is not a Surface" do
    lambda {
      @surface.blit("not a surface", [0,0])
    }.should raise_error(TypeError)
  end

  it "should raise TypeError when #blit dest is not an Array" do
    lambda {
      @surface.blit(@screen, "foo")
    }.should raise_error(TypeError)
  end

  it "should raise TypeError when #blit src is not an Array" do
    lambda { 
      @surface.blit(@screen, [0,0], "foo")
    }.should raise_error(TypeError)
  end
end



describe Surface, "(fill)" do 
  before(:each) do
    Rubygame.init()
    @surface = Surface.new([100,100])
  end

  after(:each) do
    Rubygame.quit
  end

  it "should raise TypeError when #fill color is not an Array" do
    lambda {
      @surface.fill(nil)
    }.should raise_error(TypeError)
  end

  it "should raise TypeError when #fill color is an Array of non-Numerics" do
    lambda {
      @surface.fill(["non", "numeric", "members"])
    }.should raise_error(TypeError)
  end

  it "should raise ArgumentError when #fill color is too short" do
    lambda {
      @surface.fill([0xff, 0xff])
    }.should raise_error(TypeError)
  end

  it "should raise TypeError when #fill rect is not an Array" do
    lambda {
      @surface.fill([0xff, 0xff, 0xff], "not_an_array")
    }.should raise_error(TypeError)
  end
end



describe Surface, "(get_at)" do 
  before(:each) do
    Rubygame.init()
    @surface = Surface.new([100,100])
  end

  after(:each) do
    Rubygame.quit
  end

  it "get_at should get [0,0,0,255] on a new non-alpha surface" do
    @surface.get_at(0,0).should == [0,0,0,255]
  end

#   it "get_at should get [0,0,0,0] on a new alpha surface" do
#     @surface = Surface.new([100,100], 0, [SRCALPHA])
#     @surface.get_at(0,0).should == [0,0,0,0]
#   end

  it "get_at should get the color of a filled surface" do
    @surface.fill([255,0,0])
    @surface.get_at(0,0).should == [255,0,0,255]
  end


  describe "(8-bit)" do
    before(:each) do
      Rubygame.init()
      @surface = Surface.load( test_image_8bit )
    end

    it "get_at should get the color of the pixel" do
      @surface.get_at(0,0).should == [255,0,0,255]
    end

  end
end



describe Surface, "(palette)" do 

  after(:each) do
    Rubygame.quit
  end


  describe "depth 1" do
    before :each do
      @surf = Surface.new([1,1], :depth => 1)
    end

    it "should have a palette" do
      @surf.palette.should be_instance_of(Surface::Palette)
    end

    it "palette should have 2 colors" do
      @surf.palette.size.should == 2
    end

    it "should have black and white colors" do
      @surf.palette.colors.should include(Color.rgb255([0,0,0,255]))
      @surf.palette.colors.should include(Color.rgb255([255,255,255,255]))
    end

    it "setting palette should perform Palette#replace" do
      colors = [[255,0,0,255], [0,255,0,255]]
      @surf.palette.should_receive(:replace).with(colors)
      @surf.palette = colors
    end
  end


  (2..8).each do |d|

    describe "depth #{d}" do
      before :each do
        @surf = Surface.new([1,1], :depth => d)
      end

      it "should have a Palette" do
        @surf.palette.should be_instance_of(Surface::Palette)
      end

      it "palette should have #{2**d} colors" do
        @surf.palette.size.should == 2**d
      end

      it "palette should be all black by default" do
        @surf.palette.colors.each{ |c|
          c.should == Color.rgb255([0,0,0,255])
        }
      end

      it "setting palette should perform Palette#replace" do
        colors = [[255,0,0,255], [0,255,0,255]]
        @surf.palette.should_receive(:replace).with(colors)
        @surf.palette = colors
      end
    end

  end


  describe "depth >8" do
    it "should not have a palette" do
      (9..32).each { |i|
        Surface.new([1,1], :depth => i).palette.should be_nil
      }
    end

    it "should raise SDLError when trying to set palette" do
      (9..32).each { |i|
        surf = Surface.new([1,1], :depth => i)
        expect{ surf.palette = [:red] }.to raise_error(SDLError)
      }
    end
  end


end



describe Surface::Palette do 

  it "should be Enumerable" do
    Surface::Palette.should include(Enumerable)
  end


  context ".new" do
    it "should accept one Surface with a palette" do
      surf = Surface.new([1,1], :depth => 8)
      expect{Surface::Palette.new(surf)}.to_not raise_error
    end

    it "should fail when given a Surface with no palette" do
      bad_surf = Surface.new([1,1], :depth => 16)
      expect{ Surface::Palette.new(surf) }.to raise_error
    end

    it "should fail when given no args" do
      expect{Surface::Palette.new}.to raise_error(ArgumentError)
    end

    it "should fail when given too many args" do
      expect{
        Surface::Palette.new(@surf,@surf)
      }.to raise_error(ArgumentError)
    end

    it "should fail when given an invalid arg" do
      invalid = [true, false, nil, 1, 1.2, "str", :sym, Object.new]
      invalid.each { |arg|
        expect{
          Surface::Palette.new(arg)
        }.to raise_error(TypeError)
      }
    end
  end


  (2..8).each do |depth|

    context "with depth #{depth}" do

      before :each do
        @surf = Surface.new([1,1], :depth => depth)
        @pal = @surf.palette
      end


      describe "#size" do
        it "should return the correct number of colors" do
          @pal.size.should == (2**depth)
        end
      end

      describe "#length" do
        it "should return the correct number of colors" do
          @pal.size.should == (2**depth)
        end
      end

      describe "#surface" do
        it "should return the Surface it belongs to" do
          @pal.surface.should equal(@surf)
        end
      end


      describe "#==" do
        before :each do
          @colors = (0...@pal.size).collect{ |i| Color.rgb255([i,i,i,i]) }
          @surf.palette = @colors
        end

        context "given a Palette" do
          before :each do
            @surf2 = Surface.new([1,1], :depth => depth)
            @pal2 = @surf2.palette
            @pal2.replace( @pal.colors )
          end

          it "should be true if it has all the same colors" do
            @pal.should == @pal2
          end

          it "should be false if it has different colors" do
            @pal2.replace( [[1,2,3,4]]*@pal.size )
            @pal.should_not == @pal2
          end

          it "should be false if it has a different order" do
            @pal2.replace( @pal.colors.reverse )
            @pal.should_not == @pal2
          end

          if depth > 2
            it "should be false if it has fewer colors" do
              @surf2 = Surface.new([1,1], :depth => depth - 1)
              @pal2 = @surf2.palette
              @pal2.replace( @pal.colors[0, @pal2.size] )
              @pal.should_not == @pal2
            end
          end

          if depth < 8
            it "should be false if it has more colors" do
              @surf2 = Surface.new([1,1], :depth => depth + 1)
              @pal2 = @surf2.palette
              @pal2.replace( @pal.colors[0, @pal2.size] )
              @pal.should_not == @pal2
            end
          end
        end

        context "given an Array of colors" do
          it "should be true if it has all the same colors" do
            @pal.should == @pal.colors
          end

          it "should be false if it has different colors" do
            @pal.should_not == [[1,2,3,4]]*@pal.size
          end

          it "should be false if it has a different order" do
            @pal.should_not == @pal.colors.reverse
          end

          if depth > 2
            it "should be false if it has fewer colors" do
              @pal.should_not == @pal.colors[0..-2]
            end
          end

          if depth < 8
            it "should be false if it has more colors" do
              @pal.should_not == @pal.colors[0, @pal.size]+[1,2,3,4]
            end
          end
        end

        context "given an Array of Slots" do
          before :each do
            @surf2 = Surface.new([1,1], :depth => depth)
            @pal2 = @surf2.palette
          end

          it "should be true if the slots have the same colors" do
            @pal2.replace( @pal.colors )
            @pal.should == @pal2.to_a
          end

          it "should be false if the slots have different colors" do
            @pal2.replace( [[1,2,3,4]]*@pal.size )
            @pal.should_not == @pal2.to_a
          end

          it "should be false if the slot colors have a different order" do
            @pal2.replace( @pal.colors.reverse )
            @pal.should_not == @pal2.to_a
          end

          if depth > 2
            it "should be false if it has fewer slots" do
              @pal2.replace( @pal.colors )
              @pal.should_not == @pal2.to_a[0..-2]
            end
          end

          if depth < 8
            it "should be false if it has more slots" do
              @pal2.replace( @pal.colors )
              @pal.should_not == @pal2.to_a+[@pal[0]]
            end
          end
        end

      end


      

      it "should be frozen if its Surface is frozen" do
        @surf.freeze
        @pal.should be_frozen
      end


      describe "#colors" do
        before :each do
          @colors = (0...@pal.size).collect{ |i| Color.rgb255([i,i,i,i]) }
          @surf.palette = @colors
        end

        it "should return an array of ColorRGB255 instances" do
          pc = @pal.colors
          pc.should be_instance_of(Array)
          pc.each { |color|
            color.should be_instance_of(Color::ColorRGB255)
          }
        end

        it "should return the expected number of colors" do
          @pal.colors.size.should == @pal.size
        end

        it "should return the colors in order" do
          @pal.colors.each_with_index { |color, i|
            color.to_a.should == [i,i,i,i]
          }
        end

        it "all default colors should be frozen" do
          surf = Surface.new([1,1], :depth => depth)
          surf.palette.colors.each { |color| color.should be_frozen }
        end

        it "all colors should be frozen" do
          @pal.colors.each { |color| color.should be_frozen }
        end

        it "modifying the array should not affect the Palette" do
          pc = @pal.colors
          pc[1] = Color.rgb255([1,2,3,4])
          @pal.colors[1].should == Color.rgb255([1,1,1,1])
        end

        it "modifying the Palette later should not affect the array" do
          pc = @pal.colors
          @pal[1] = Color.rgb255([1,2,3,4])
          pc[1].should == Color.rgb255([1,1,1,1])
        end
      end


      describe "#color_at" do
        before :each do
          @colors = (0...@pal.size).collect{ |i| Color.rgb255([i,i,i,i]) }
          @surf.palette = @colors
        end

        it "should return a ColorRGB255 instance" do
          @pal.color_at(1).should be_instance_of(Color::ColorRGB255)
        end

        it "should return the expected color" do
          @pal.color_at(1).should == [1,1,1,1]
        end

        it "should understand negative indices" do
          i = @pal.size - 1
          @pal.color_at(-1).should == [i,i,i,i]
          @pal.color_at(-@pal.size).should == [0,0,0,0]
        end

        it "should raise IndexError if index is out of bounds" do
          i = @pal.size
          expect{ @pal.color_at(i) }.to raise_error(IndexError)
          expect{ @pal.color_at(-i - 1) }.to raise_error(IndexError)
        end

        it "the color should be frozen" do
          @pal.color_at(1).should be_frozen
        end
      end


      describe "#to_a" do
        it "should return an array of Palette::Slot instances" do
          pa = @pal.to_a
          pa.should be_instance_of(Array)
          pa.each { |slot|
            slot.should be_instance_of(Surface::Palette::Slot)
          }
        end

        it "should return the expected number of slots" do
          @pal.to_a.size.should == @pal.size
        end

        it "should return the slots in order" do
          @pal.to_a.each_with_index { |slot, i|
            slot.index.should == i
          }
        end

        it "modifying the array should not affect the Palette" do
          @pal[0] = [0,0,0,0]
          @pal[1] = [1,1,1,1]
          pa = @pal.to_a
          pa[0] = pa[1]
          @pal[0].should == [0,0,0,0]
        end
      end


      describe "#each" do
        it "should yield Palette::Slot instances" do
          @pal.each{ |slot|
            slot.should be_instance_of(Surface::Palette::Slot)
          }
        end

        it "should yield the expected number of slots" do
          count = 0
          @pal.each{ |slot| count += 1 }
          count.should == @pal.size
        end

        it "should yield the slots in order" do
          @pal.each_with_index{ |slot, index|
            slot.index.should == index
          }
        end
      end


      describe "#at" do
        it "should return a Palette::Slot instance" do
          @pal.at(1).should be_instance_of(Surface::Palette::Slot)
        end

        it "the slot should belong to this Palette" do
          @pal.at(1).palette.should equal(@pal)
        end

        it "should return the expected slot" do
          @pal.at(1).index.should == 1
        end

        it "should understand negative indices" do
          @pal.at(-1).index.should == @pal.size - 1
          @pal.at(-@pal.size).index.should == 0
        end

        it "should raise IndexError if index is out of bounds" do
          i = @pal.size
          expect{ @pal.at(i) }.to raise_error(IndexError)
          expect{ @pal.at(-i - 1) }.to raise_error(IndexError)
        end
      end


      describe "#[]" do
        it "should return a Palette::Slot instance" do
          @pal[1].should be_instance_of(Surface::Palette::Slot)
        end

        it "the slot should belong to this Palette" do
          @pal[1].palette.should equal(@pal)
        end

        it "should return the expected slot" do
          @pal[1].index.should == 1
        end

        it "should understand negative indices" do
          @pal[-1].index.should == @pal.size - 1
          @pal[-@pal.size].index.should == 0
        end

        it "should raise IndexError if index is out of bounds" do
          i = @pal.size
          expect{ @pal[i] }.to raise_error(IndexError)
          expect{ @pal[-i - 1] }.to raise_error(IndexError)
        end
      end


      describe "#[]=" do
        it "should understand negative indices" do
          color = Color.rgb255([1,2,3,4])
          @pal[-1] = color
          @pal[@pal.size - 1].color.should == color
          color2 = Color.rgb255([4,3,2,1])
          @pal[-@pal.size] = color2
          @pal[0].color.should == color2
        end

        it "should raise IndexError if index is out of bounds" do
          color = Color.rgb255([1,2,3,4])
          i = @pal.size
          expect{ @pal[i] = color  }.to raise_error(IndexError)
          expect{ @pal[-i - 1] = color }.to raise_error(IndexError)
        end

        color_scenarios = {
          "given a Color"             => Rubygame::Color[:sky_blue],
          "given a [R,G,B] array"     => [135, 206, 235],
          "given a [R,G,B,A] array"   => [135, 206, 235, 255],
          "given a color name symbol" => :sky_blue,
          "given a color name string" => "sky_blue",
          "given a hex color string"  => "#87ceeb",
        }

        color_scenarios.each do |scenario, arg|
          context scenario do
            it "should set the palette color" do
              @pal[1] = arg
              @pal[1].color.should == Color.rgb255([135, 206, 235, 255])
            end
          end
        end

        context "given an integer" do
          it "should use the color from that index" do
            @pal[1] = [1,2,3,4]
            @pal[0] = 1
            @pal[0].color.should == [1,2,3,4]
          end

          it "should raise IndexError if it is out of bounds" do
            i = @pal.size
            expect{ @pal[0] = i }.to raise_error(IndexError)
            expect{ @pal[0] = -i - 1 }.to raise_error(IndexError)
          end
        end

        context "given a Slot from itself" do
          it "should use the color from that slot" do
            @pal[1] = [1,2,3,4]
            @pal[0] = @pal[1]
            @pal[0].color.should == [1,2,3,4]
          end
        end

        context "given a Slot from another Palette" do
          it "should use the color from that Palette's slot" do
            surf2 = Surface.new([1,1], :depth => 8)
            surf2.palette[1] = [1,2,3,4]
            @pal[0] = surf2.palette[1]
            @pal[0].color.should == [1,2,3,4]
          end
        end
      end # describe "#[]="


      describe "#replace" do

        it "should return self" do
          @pal.replace([[1,2,3,4]]).should equal(@pal)
        end

        it "should replace all the colors" do
          colors = (0...@pal.size).collect{ |i| [i,i,i,i] }
          @pal.replace(colors)
          @pal.colors.each_with_index{ |color, i|
            color.should == colors[i]
          }
        end

        context "given too many colors" do
          it "should ignore the excess colors" do
            colors = (0...@pal.size+1).collect{ |i| [i,i,i,i] }
            expect{ @pal.replace(colors) }.to_not raise_error
            @pal[0].color.should == [0,0,0,0]
            @pal[-1].color.should == [@pal.size-1]*4
          end
        end

        context "given too few colors" do
          it "should use the given colors for the start" do
            @pal.replace([[1,2,3,4]])
            @pal[0].color.should == [1,2,3,4]
          end

          it "should fill in the rest with solid black" do
            @pal.replace([[1,2,3,4]])
            (1...@pal.size).each{ |i|
              @pal[i].color.should == [0,0,0,255]
            }
          end
        end

        context "given an empty array" do
          it "should fill in the entire palette with solid black" do
            @pal.replace([])
            (0...@pal.size).each{ |i|
              @pal[i].color.should == [0,0,0,255]
            }
          end
        end

        color_scenarios = {
          "Colors"             => Rubygame::Color[:sky_blue],
          "[R,G,B] arrays"     => [135, 206, 235],
          "[R,G,B,A] arrays"   => [135, 206, 235, 255],
          "color name symbols" => :sky_blue,
          "color name strings" => "sky_blue",
          "hex color strings"  => "#87ceeb",
        }

        color_scenarios.each do |scenario, arg|
          it "should understand #{scenario}" do
            @pal.replace( [arg]*@pal.size )
            @pal[0].color.should == Color.rgb255([135, 206, 235, 255])
          end
        end

        it "should interpret integers as own Slot indices" do
          @pal[1] = [1,2,3,4]
          @pal.replace([1]*@pal.size)
          @pal[0].color.should == [1,2,3,4]
        end

        it "should understand Slots from itself" do
          @pal[1] = [1,2,3,4]
          @pal.replace([@pal[1]]*@pal.size)
          @pal[0].color.should == [1,2,3,4]
        end

        it "should understand Slots from another Palette" do
          surf2 = Surface.new([1,1], :depth => 8)
          surf2.palette[1] = [1,2,3,4]
          @pal.replace([surf2.palette[1]]*@pal.size)
          @pal[0].color.should == [1,2,3,4]
        end


        invalid_args = {
          "true"          => true,
          "false"         => false,
          "nil"           => nil,
          "a float"       => 1.0,
          "a short array" => [1,2],
          "a hash"        => {1=>2},
          "some object"   => Object.new,
        }

        invalid_args.each do |scenario, arg|
          context "given an invalid value (#{scenario})" do

            it "should raise error" do
              expect{ @pal.replace([[1,2,3,4], arg]) }.to raise_error
            end

            it "should not affect the Palette" do
              orig = @pal.colors
              begin
                @pal.replace([[1,2,3,4], arg])
              rescue
              end
              @pal.colors.should == orig
            end

          end
        end

      end # describe "#replace"


      describe "#reverse!" do
        it "should return self" do
          @pal.reverse!.should equal(@pal)
        end

        it "should reverse the order of colors" do
          expected = @pal.colors.reverse
          @pal.reverse!
          @pal.colors.should == expected
        end
      end


      describe "#rotate!" do
        before :each do
          @colors = (0...@pal.size).collect{ |i| Color.rgb255([i,i,i,i]) }
          @surf.palette = @colors
        end

        it "should return self" do
          @pal.rotate!(1).should equal(@pal)
        end

        context "given a positive integer" do
          it "should move colors at the front to the back" do
            expected = @pal.colors[2..-1] + @pal.colors[0..1]
            @pal.rotate!(2)
            @pal.colors.should == expected
          end
        end

        context "given a negative integer" do
          it "should move colors at the back to the front" do
            expected = @pal.colors[-2..-1] + @pal.colors[0..-3]
            @pal.rotate!(-2)
            @pal.colors.should == expected
          end
        end

        context "given zero" do
          it "should have no effect" do
            expected = @pal.colors
            @pal.rotate!(0)
            @pal.colors.should == expected
          end
        end

        invalid_args = {
          "true"          => true,
          "false"         => false,
          "nil"           => nil,
          "a string"      => "str",
          "a symbol"      => :sym,
          "a float"       => 1.0,
          "an array"      => [1,2],
          "a hash"        => {1=>2},
          "some object"   => Object.new,
        }

        invalid_args.each do |scenario, arg|
          context "given an invalid value (#{scenario})" do

            it "should raise TypeError" do
              expect{ @pal.rotate!(arg) }.to raise_error(TypeError)
            end

            it "should not affect the Palette" do
              orig = @pal.colors
              begin
                @pal.rotate!(arg)
              rescue
              end
              @pal.colors.should == orig
            end

          end
        end
      end


      describe "#shuffle!" do
        before :each do
          @colors = (0...@pal.size).collect{ |i| Color.rgb255([i,i,i,i]) }
          @surf.palette = @colors
        end

        it "should return self" do
          @pal.shuffle!.should equal(@pal)
        end

        it "should have all the original colors" do
          orig = @pal.colors
          @pal.shuffle!
          orig.each{ |c| @pal.colors.should include(c) }
        end

        it "should have the same size" do
          orig = @pal.colors
          @pal.shuffle!
          @pal.size.should == orig.size
        end

        it "should shuffle the colors" do
          # This is cheating, but I can't think of any other way to
          # reliably test that the colors are shuffled.

          colors = @pal.instance_eval{ @colors }
          colors.should_receive(:shuffle!)
          @pal.shuffle!
        end
      end


    end # context "with depth ..."
  end # (2..8).each

end



describe Surface::Palette::Slot do

  before :each do
    @surf = Surface.new([1,1], :depth => 8)
    @pal = @surf.palette
    @colors = (0...@pal.size).collect{ |i| [i,i,i,i] }
    @pal.replace(@colors)
  end


  describe ".new" do
    it "should accept a Palette and an integer index" do
      expect{
        Surface::Palette::Slot.new(@pal, 1)
      }.to_not raise_error
    end

    invalid_args = {
      "true"          => true,
      "false"         => false,
      "nil"           => nil,
      "a string"      => "str",
      "a symbol"      => :sym,
      "a float"       => 1.0,
      "an array"      => [1,2],
      "a hash"        => {1=>2},
      "some object"   => Object.new,
    }

    invalid_args.each do |scenario, arg|
      it "should fail if palette is invalid (#{scenario})" do
        expect{
          Surface::Palette::Slot.new(arg, 1)
        }.to raise_error(TypeError)
      end

      it "should fail if index is invalid (#{scenario})" do
        expect{
          Surface::Palette::Slot.new(@pal, arg)
        }.to raise_error(TypeError)
      end
    end
  end


  describe "#palette" do
    before :each do
      @slot = Surface::Palette::Slot.new(@pal, 1)
    end

    it "should return the Slot's palette" do
      slot = Surface::Palette::Slot.new(@pal, 1)
      slot.palette.should equal(@pal)
    end

    it "should not be writable" do
      slot = Surface::Palette::Slot.new(@pal, 1)
      expect{ slot.palette = @pal }.to raise_error(NoMethodError)
    end
  end


  describe "#index" do
    before :each do
      @slot = Surface::Palette::Slot.new(@pal, 1)
    end

    it "should return the Slot's index" do
      slot = Surface::Palette::Slot.new(@pal, 1)
      slot.index.should equal(1)
    end

    it "should not be writable" do
      slot = Surface::Palette::Slot.new(@pal, 1)
      expect{ slot.index = 2 }.to raise_error(NoMethodError)
    end
  end


  describe "#==" do
    before :each do
      @slot = Surface::Palette::Slot.new(@pal, 1)
    end

    context "given itself" do
      it "should be true" do
        @slot.should == @slot
      end
    end

    context "given an equivalent Slot" do
      it "should be true" do
        @slot.should == Surface::Palette::Slot.new(@pal, 1)
      end
    end

    context "given an integer" do
      it "should be true if the integer matches index" do
        @slot.should == 1
      end

      it "should be false if the integer does not match index" do
        @slot.should_not == 2
      end
    end

    context "given another Slot" do
      it "should be true if the colors are equal" do
        surf2 = Surface.new([1,1], :depth => 8)
        surf2.palette[0] = [1,1,1,1]
        @slot.should == Surface::Palette::Slot.new(surf2.palette, 0)
      end

      it "should be false if the colors are not equal" do
        surf2 = Surface.new([1,1], :depth => 8)
        surf2.palette[0] = [2,2,2,2]
        @slot.should_not == Surface::Palette::Slot.new(surf2.palette, 0)
      end
    end

    context "given a ColorRGB255" do
      it "should be true if the colors are equal" do
        @slot.should == Color.rgb255([1,1,1,1])
      end

      it "should be false if the colors are not equal" do
        @slot.should_not == Color.rgb255([2,2,2,2])
      end
    end

    context "given a ColorRGB" do
      it "should be true if the colors are equal" do
        @slot.should == Color.rgb255([1,1,1,1]).to_rgb
      end

      it "should be false if the colors are not equal" do
        @slot.should_not == Color.rgb255([2,2,2,2]).to_rgb
      end
    end

    context "given a ColorHSV" do
      it "should be true if the colors are equal" do
        @slot.should == Color.rgb255([1,1,1,1]).to_hsv
      end

      it "should be false if the colors are not equal" do
        @slot.should_not == Color.rgb255([2,2,2,2]).to_hsv
      end
    end

    context "given a ColorHSL" do
      it "should be true if the colors are equal" do
        @slot.should == Color.rgb255([1,1,1,1]).to_hsl
      end

      it "should be false if the colors are not equal" do
        @slot.should_not == Color.rgb255([2,2,2,2]).to_hsl
      end
    end

    context "given an array of integers" do
      it "should be true if equal to the Slot's color" do
        @slot.should == [1,1,1,1]
      end

      it "should be false if not equal to the Slot's color" do
        @slot.should_not == [2,2,2,2]
      end
    end

    invalid_args = {
      "true"          => true,
      "false"         => false,
      "nil"           => nil,
      "a string"      => "str",
      "a symbol"      => :sym,
      "a float"       => 1.0,
      "a short array" => [1,2],
      "a hash"        => {1=>2},
      "some object"   => Object.new,
    }

    invalid_args.each do |scenario, arg|
      context "given #{scenario}" do
        it "should be false" do
          @slot.should_not == arg
        end
      end
    end

  end # describe "#=="


  describe "#eql?" do
    before :each do
      @slot = Surface::Palette::Slot.new(@pal, 1)
    end

    context "given a Slot" do
      it "should be true if it has the same palette and index" do
        @slot.should eql( Surface::Palette::Slot.new(@pal,1) )
      end

      it "should be false if it has a different palette" do
        pal2 = Surface.new([1,1], :depth => 8).palette
        @slot.should_not eql( Surface::Palette::Slot.new(pal2,1) )
      end

      it "should be false if it has a different index" do
        @slot.should_not eql(Surface::Palette::Slot.new(@pal,2) )
      end
    end

    invalid_args = {
      "true"              => true,
      "false"             => false,
      "nil"               => nil,
      "a string"          => "str",
      "a symbol"          => :sym,
      "an integer"        => 1,
      "a float"           => 1.0,
      "a short array"     => [1,2],
      "a hash"            => {1=>2},
      "some object"       => Object.new,
      "a [R,G,B] array"   => [1,1,1],
      "a [R,G,B,A] array" => [1,1,1,1],
      "a Color"           => Color.rgb255([1,1,1,1])
    }

    invalid_args.each do |scenario, arg|
      context "given #{scenario}" do
        it "should be false" do
          @slot.should_not eql(arg)
        end
      end
    end

  end # describe "#eql?"


  describe "#color" do
    before :each do
      @slot = Surface::Palette::Slot.new(@pal, 1)
    end

    it "should return a ColorRGB255 instance" do
      @slot.color.should be_instance_of(Color::ColorRGB255)
    end

    it "should equal the Palette's color with this index" do
      @slot.color.should == [1,1,1,1]
    end

    it "should reflect Palette changes made after Slot creation" do
      @pal[1] = [1,2,3,4]
      @slot.color.should == [1,2,3,4]
    end

    it "the color should be frozen" do
      @slot.color.should be_frozen
    end
  end


  describe "#to_rgba_ary" do
    before :each do
      @slot = Surface::Palette::Slot.new(@pal, 1)
    end

    it "should return an Array" do
      @slot.to_rgba_ary.should be_instance_of( Array )
    end

    it "should equal the color as RGBA (0.0..1.0)" do
      @slot.to_rgba_ary.should == [1/255.0]*4
    end

    it "should reflect Palette changes made after Slot creation" do
      @pal[1] = [1,2,3,4]
      @slot.to_rgba_ary.should == [1,2,3,4].collect{|i| i/255.0}
    end
  end


  describe "#to_sdl_rgba_ary" do
    before :each do
      @slot = Surface::Palette::Slot.new(@pal, 1)
    end

    it "should return an Array" do
      @slot.to_sdl_rgba_ary.should be_instance_of( Array )
    end

    it "should equal the color as RGBA (0..255)" do
      @slot.to_sdl_rgba_ary.should == [1,1,1,1]
    end

    it "should reflect Palette changes made after Slot creation" do
      @pal[1] = [1,2,3,4]
      @slot.to_sdl_rgba_ary.should == [1,2,3,4]
    end
  end


  models = {
    "to_rgb"    => Color::ColorRGB,
    "to_rgb255" => Color::ColorRGB255,
    "to_hsv"    => Color::ColorHSV,
    "to_hsl"    => Color::ColorHSL,
  }

  models.each do |method,klass|

    describe "##{method}" do
      before :each do
        @slot = Surface::Palette::Slot.new(@pal, 1)
      end

      it "should return a #{klass.name}" do
        @slot.send(method).should be_instance_of( klass )
      end

      it "should equal the slot's color" do
        @slot.send(method).should == @slot.color
      end

      it "should reflect Palette changes made after Slot creation" do
        new_color = Color.rgb255([1,2,3,4])
        @pal[1] = new_color
        @slot.send(method).should == new_color
      end
    end

  end

end



describe "A frozen", Surface do

  before :each do
    @surface = Surface.new([10,10])
    @surface.freeze
  end


  it "should be frozen" do
    @surface.should be_frozen
  end


  it "alpha should NOT raise error" do
    lambda{ @surface.alpha }.should_not raise_error
  end

  it "set_alpha should raise error" do
    lambda{ @surface.set_alpha(0) }.should raise_error
  end

  it "alpha= should raise error" do
    lambda{ @surface.alpha = 0 }.should raise_error
  end

 
  it "opacity should NOT raise error" do
    lambda{ @surface.opacity }.should_not raise_error
  end

  it "opacity with arg should raise error" do
    lambda{ @surface.opacity(0) }.should raise_error
  end

  it "opacity= should raise error" do
    lambda{ @surface.opacity = 0 }.should raise_error
  end

 
  it "colorkey should NOT raise error" do
    lambda{ @surface.colorkey }.should_not raise_error
  end

  it "set_colorkey should raise error" do
    lambda{ @surface.set_colorkey(:blue) }.should raise_error
  end

  it "colorkey= should raise error" do
    lambda{ @surface.colorkey = :blue }.should raise_error
  end

 
  it "palette should NOT raise error" do
    lambda{ @surface.palette }.should_not raise_error
  end

  it "palette= should raise error" do
    @surface = Surface.new([10,10], :depth => 2)
    @surface.freeze
    lambda{ @surface.palette = [:blue] }.should raise_error
  end


  it "unfrozen-on-frozen blit should raise error" do
    @surface2 = Surface.new([10,10])
    lambda{ @surface2.blit(@surface,[0,0]) }.should raise_error
  end

  it "frozen-on-frozen blit should raise error" do
    @surface2 = Surface.new([10,10])
    @surface2.freeze
    lambda{ @surface.blit(@surface2,[0,0]) }.should raise_error
  end

  it "frozen-on-unfrozen blit should NOT raise error" do
    @surface2 = Surface.new([10,10])
    lambda{ @surface.blit(@surface2,[0,0]) }.should_not raise_error
  end


  it "fill should raise error" do
    lambda{ @surface.fill(:blue) }.should raise_error
  end


  it "get_at should NOT raise error" do
    lambda{ @surface.get_at([0,0]) }.should_not raise_error
  end

  it "set_at should raise error" do
    lambda{ @surface.set_at([0,0],:blue) }.should raise_error
  end


  it "pixels should NOT raise error" do
    lambda{ @surface.pixels }.should_not raise_error
  end

  it "pixels= should raise error" do
    lambda{ @surface.pixels = @surface.pixels }.should raise_error
  end


  it "clip should NOT raise error" do
    lambda{ @surface.clip }.should_not raise_error
  end

  it "clip= should raise error" do
    lambda{ @surface.clip = Rect.new(0,0,1,1) }.should raise_error
  end


  it "draw_line should raise error" do
    if @surface.respond_to? :draw_line
      lambda{ @surface.draw_line([0,0],[1,1],:white) }.should raise_error
    else
      pending "No draw_line support. Is SDL_gfx available?"
    end
  end

  it "draw_line_a should raise error" do
    if @surface.respond_to? :draw_line_a
      lambda{ @surface.draw_line_a([0,0],[1,1],:white) }.should raise_error
    else
      pending "No draw_line_a support. Is SDL_gfx available?"
    end
  end


  it "draw_box should raise error" do
    if @surface.respond_to? :draw_box
      lambda{ @surface.draw_box([0,0],[1,1],:white) }.should raise_error
    else
      pending "No draw_box support. Is SDL_gfx available?"
    end
  end

  it "draw_box_s should raise error" do
    if @surface.respond_to? :draw_box_s
      lambda{ @surface.draw_box_s([0,0],[1,1],:white) }.should raise_error
    else
      pending "No draw_box_s support. Is SDL_gfx available?"
    end
  end


  it "draw_circle should raise error" do
    if @surface.respond_to? :draw_circle
      lambda{ @surface.draw_circle([0,0],1,:white) }.should raise_error
    else
      pending "No draw_circle support. Is SDL_gfx available?"
    end
  end

  it "draw_circle_a should raise error" do
    if @surface.respond_to? :draw_circle_a
      lambda{ @surface.draw_circle_a([0,0],1,:white) }.should raise_error
    else
      pending "No draw_circle_a support. Is SDL_gfx available?"
    end
  end

  it "draw_circle_s should raise error" do
    if @surface.respond_to? :draw_circle_s
      lambda{ @surface.draw_circle_s([0,0],1,:white) }.should raise_error
    else
      pending "No draw_circle_s support. Is SDL_gfx available?"
    end
  end


  it "draw_ellipse should raise error" do
    if @surface.respond_to? :draw_ellipse
      lambda{ @surface.draw_ellipse([0,0],[1,1],:white) }.should raise_error
    else
      pending "No draw_ellipse support. Is SDL_gfx available?"
    end
  end

  it "draw_ellipse_a should raise error" do
    if @surface.respond_to? :draw_ellipse_a
      lambda{ @surface.draw_ellipse_a([0,0],[1,1],:white) }.should raise_error
    else
      pending "No draw_ellipse_a support. Is SDL_gfx available?"
    end
  end

  it "draw_ellipse_s should raise error" do
    if @surface.respond_to? :draw_ellipse_s
      lambda{ @surface.draw_ellipse_s([0,0],[1,1],:white) }.should raise_error
    else
      pending "No draw_ellipse_s support. Is SDL_gfx available?"
    end
  end


  it "draw_arc should raise error" do
    if @surface.respond_to? :draw_arc
      lambda{ @surface.draw_arc([0,0],1,[0,1],:white) }.should raise_error
    else
      pending "No draw_arc support. Is SDL_gfx available?"
    end
  end

  it "draw_arc_s should raise error" do
    if @surface.respond_to? :draw_arc_s
      lambda{ @surface.draw_arc_s([0,0],1,[0,1],:white) }.should raise_error
    else
      pending "No draw_arc_s support. Is SDL_gfx available?"
    end
  end


  it "draw_polygon should raise error" do
    if @surface.respond_to? :draw_polygon
      lambda{ @surface.draw_polygon([[0,0],[1,1]],:white) }.should raise_error
    else
      pending "No draw_polygon support. Is SDL_gfx available?"
    end
  end

  it "draw_polygon_a should raise error" do
    if @surface.respond_to? :draw_polygon_a
      lambda{ @surface.draw_polygon_a([[0,0],[1,1]],:white) }.should raise_error
    else
      pending "No draw_polygon_a support. Is SDL_gfx available?"
    end
  end

  it "draw_polygon_s should raise error" do
    if @surface.respond_to? :draw_polygon_s
      lambda{ @surface.draw_polygon_s([[0,0],[1,1]],:white) }.should raise_error
    else
      pending "No draw_polygon_s support. Is SDL_gfx available?"
    end
  end


  it "draw_curve should raise error" do
    if @surface.respond_to? :draw_curve
      lambda{ @surface.draw_curve([[0,0],[1,1]],:white) }.should raise_error
    else
      pending "No draw_curve support. Is SDL_gfx available?"
    end
  end


  it "rotozoom should NOT raise error" do
    if @surface.respond_to? :rotozoom
      lambda{ @surface.rotozoom(1,1) }.should_not raise_error
    else
      pending "No rotozoom support. Is SDL_gfx available?"
    end
  end

  it "zoom should NOT raise error" do
    if @surface.respond_to? :zoom
      lambda{ @surface.zoom(1) }.should_not raise_error
    else
      pending "No zoom support. Is SDL_gfx available?"
    end
  end

  it "zoom_to should NOT raise error" do
    if @surface.respond_to? :zoom_to
      lambda{ @surface.zoom_to(5,5) }.should_not raise_error
    else
      pending "No zoom_to support. Is SDL_gfx available?"
    end
  end

  it "flip should NOT raise error" do
    if @surface.respond_to? :flip
      lambda{ @surface.flip(true,true) }.should_not raise_error
    else
      pending "No flip support. Is SDL_gfx available?"
    end
  end

end



describe Surface, "(vector support)" do

  before(:each) do
    Rubygame.init()
    @surface = Surface.new([100,100])
  end

  after(:each) do
    Rubygame.quit
  end

  it "#blit should accept a Vector2 for dest" do
    lambda {
      @surface.blit(Surface.new([100,100]), Vector2[0,0])
    }.should_not raise_error
  end

  it "#get_at should accept a Vector2 for position" do
    @surface.get_at(Vector2[0,0]).should == [0,0,0,255]
  end

  it "#set_at should accept a Vector2 for position" do
    @surface.set_at(Vector2[0,0], :blue)
    @surface.get_at(0,0).should == [0,0,255,255]
  end


  it "draw_line should accept Vector2s" do
    if @surface.respond_to? :draw_line
      lambda{
        @surface.draw_line( Vector2[0,0], Vector2[1,1], :white )
      }.should_not raise_error
    else
      pending "No draw_line support. Is SDL_gfx available?"
    end
  end

  it "draw_line_a should accept Vector2s" do
    if @surface.respond_to? :draw_line_a
      lambda{
        @surface.draw_line_a( Vector2[0,0], Vector2[1,1], :white )
      }.should_not raise_error
    else
      pending "No draw_line_a support. Is SDL_gfx available?"
    end
  end


  it "draw_box should accept Vector2s" do
    if @surface.respond_to? :draw_box
      lambda{
        @surface.draw_box( Vector2[0,0], Vector2[1,1], :white )
      }.should_not raise_error
    else
      pending "No draw_box support. Is SDL_gfx available?"
    end
  end

  it "draw_box_s should accept Vector2s" do
    if @surface.respond_to? :draw_box_s
      lambda{
        @surface.draw_box_s( Vector2[0,0], Vector2[1,1], :white )
      }.should_not raise_error
    else
      pending "No draw_box_s support. Is SDL_gfx available?"
    end
  end


  it "draw_circle should accept a Vector2" do
    if @surface.respond_to? :draw_circle
      lambda{
        @surface.draw_circle( Vector2[1,1], 1, :white )
      }.should_not raise_error
    else
      pending "No draw_circle support. Is SDL_gfx available?"
    end
  end

  it "draw_circle_a should accept a Vector2" do
    if @surface.respond_to? :draw_circle_a
      lambda{
        @surface.draw_circle_a( Vector2[1,1], 1, :white )
      }.should_not raise_error
    else
      pending "No draw_circle_a support. Is SDL_gfx available?"
    end
  end

  it "draw_circle_s should accept a Vector2" do
    if @surface.respond_to? :draw_circle_s
      lambda{
        @surface.draw_circle_s( Vector2[1,1], 1, :white )
      }.should_not raise_error
    else
      pending "No draw_circle_s support. Is SDL_gfx available?"
    end
  end


  it "draw_ellipse should accept a Vector2" do
    if @surface.respond_to? :draw_ellipse
      lambda{
        @surface.draw_ellipse( Vector2[1,1], [1,2], :white )
      }.should_not raise_error
    else
      pending "No draw_ellipse support. Is SDL_gfx available?"
    end
  end

  it "draw_ellipse_a should accept a Vector2" do
    if @surface.respond_to? :draw_ellipse_a
      lambda{
        @surface.draw_ellipse_a( Vector2[1,1], [1,2], :white )
      }.should_not raise_error
    else
      pending "No draw_ellipse_a support. Is SDL_gfx available?"
    end
  end

  it "draw_ellipse_s should accept a Vector2" do
    if @surface.respond_to? :draw_ellipse_s
      lambda{
        @surface.draw_ellipse_s( Vector2[1,1], [1,2], :white )
      }.should_not raise_error
    else
      pending "No draw_ellipse_s support. Is SDL_gfx available?"
    end
  end


  it "draw_arc should accept a Vector2" do
    if @surface.respond_to? :draw_arc
      lambda{
        @surface.draw_arc( Vector2[1,1], 1, [0,1], :white )
      }.should_not raise_error
    else
      pending "No draw_arc support. Is SDL_gfx available?"
    end
  end

  it "draw_arc_s should accept a Vector2" do
    if @surface.respond_to? :draw_arc_s
      lambda{
        @surface.draw_arc_s( Vector2[1,1], 1, [0,1], :white )
      }.should_not raise_error
    else
      pending "No draw_arc_s support. Is SDL_gfx available?"
    end
  end


  it "draw_polygon should accept Vector2s" do
    if @surface.respond_to? :draw_polygon
      lambda{
        points = [Vector2[1,1], Vector2[1,2], Vector2[2,2]]
        @surface.draw_polygon( points, :white )
      }.should_not raise_error
    else
      pending "No draw_polygon support. Is SDL_gfx available?"
    end
  end

  it "draw_polygon_a should accept Vector2s" do
    if @surface.respond_to? :draw_polygon_a
      lambda{
        points = [Vector2[1,1], Vector2[1,2], Vector2[2,2]]
        @surface.draw_polygon_a( points, :white )
      }.should_not raise_error
    else
      pending "No draw_polygon_a support. Is SDL_gfx available?"
    end
  end

  it "draw_polygon_s should accept Vector2s" do
    if @surface.respond_to? :draw_polygon_s
      lambda{
        points = [Vector2[1,1], Vector2[1,2], Vector2[2,2]]
        @surface.draw_polygon_s( points, :white )
      }.should_not raise_error
    else
      pending "No draw_polygon_s support. Is SDL_gfx available?"
    end
  end


  it "draw_curve should accept Vector2s" do
    if @surface.respond_to? :draw_curve
      lambda{
        points = [Vector2[1,1], Vector2[1,2], Vector2[2,2]]
        @surface.draw_curve( points, :white )
      }.should_not raise_error
    else
      pending "No draw_curve support. Is SDL_gfx available?"
    end
  end

end



describe Surface do

  context "without an alpha channel" do
    it "should be flat" do
      surface = Surface.new([10,10], :alpha => false)
      surface.should be_flat
    end
  end

  context "with an alpha channel" do
    it "should not be flat" do
      surface = Surface.new([10,10], :alpha => true)
      surface.should_not be_flat
    end
  end

end



describe Surface, "#flatten" do

  shared_examples_for "flatten" do |args|
    args ||= []

    it "should return a new Surface" do
      orig_color = @surface.get_at([0,0])
      s = @surface.flatten(*args)
      s.fill(:red)
      @surface.get_at([0,0]).should == orig_color
    end

    it "should return a flat Surface" do
      @surface.flatten(*args).should be_flat
    end

    it "should not modify the original Surface" do
      is_flat = @surface.flat?
      @surface.flatten(*args)
      @surface.flat?.should == is_flat
    end


    # Some examples of invalid args
    invalid_scenarios =
      [
       ["given true",               [true],       TypeError],
       ["given a bad color symbol", [:foo],       IndexError],
       ["given a bad color name",   ["foo"],      IndexError],
       ["given an integer",         [1],          TypeError],
       ["given a float",            [2.3],        TypeError],
       ["given an empty array",     [[]],         TypeError],
       ["given a hash",             [{}],         TypeError],
       ["given some object",        [Object.new], TypeError],
      ]

    invalid_scenarios.each do |scenario, invargs, error|
      context scenario do
        it "should raise #{error}" do
          expect{ @surface.flatten(*invargs) }.to raise_error(error)
        end
      end
    end

  end


  context "with an alpha channel" do

    before(:each) do
      Rubygame.init()
      @surface = Surface.new([3,1], :depth => 32, :alpha => true)
      @surface.set_at( [0,0], [0, 128, 255,   0] )
      @surface.set_at( [1,0], [0, 128, 255, 128] )
      @surface.set_at( [2,0], [0, 128, 255, 255] )
    end

    after(:each) do
      Rubygame.quit
    end


    nocolor_scenarios = {
      "given no args" => [],
      "given nil"     => [nil],
      "given false"   => [false],
    }

    nocolor_scenarios.each do |scenario, args|
      context scenario do
        it_should_behave_like "flatten", args

        it "should only affect the alpha channel" do
          s = @surface.flatten(*args)
          s.get_at([0,0]).should == [0, 128, 255, 255]
          s.get_at([1,0]).should == [0, 128, 255, 255]
          s.get_at([2,0]).should == [0, 128, 255, 255]
        end
      end
    end


    color_scenarios = {
      "given a color name symbol" => [:sky_blue],
      "given a color name string" => ["sky_blue"],
      "given a hex color string"  => ["#87ceeb"],
      "given a Color"             => [Rubygame::Color[:sky_blue]],
      "given a [R,G,B] array"     => [[135, 206, 235]],
      "given a [R,G,B,A] array"   => [[135, 206, 235, 128]],
    }

    color_scenarios.each do |scenario, args|

      context scenario do
        it_should_behave_like "flatten", args

        it "should blit on top of the solid color" do
          s = @surface.flatten(*args)
          s.get_at([0,0]).should == [135, 206, 235, 255]
          s.get_at([1,0]).should == [ 67, 167, 245, 255]
          s.get_at([2,0]).should == [  0, 128, 255, 255]
        end
      end

    end

  end


  context "with no alpha channel" do

    before(:each) do
      Rubygame.init()
      @surface = Surface.new([3,1], :depth => 32)
      @surface.set_at( [0,0], [0, 128, 255] )
      @surface.set_at( [1,0], [0, 128, 255] )
      @surface.set_at( [2,0], [0, 128, 255] )
    end

    after(:each) do
      Rubygame.quit
    end


    scenarios = {
      "given no argument"         => [],
      "given nil"                 => [nil],
      "given false"               => [false],
      "given a color name symbol" => [:sky_blue],
      "given a color name string" => ["sky_blue"],
      "given a hex color string"  => ["#87ceeb"],
      "given a Color"             => [Rubygame::Color[:sky_blue]],
      "given a [R,G,B] array"     => [[135, 206, 235]],
      "given a [R,G,B,A] array"   => [[135, 206, 235, 128]],
    }

    scenarios.each do |scenario, args|

      context scenario do
        it_should_behave_like "flatten", args

        it "should not affect any color channel" do
          s = @surface.flatten(*args)
          s.get_at([0,0]).should == [0, 128, 255, 255]
          s.get_at([1,0]).should == [0, 128, 255, 255]
          s.get_at([2,0]).should == [0, 128, 255, 255]
        end
      end

    end

  end
end



describe Surface, "#opacity" do

  before :each do
    @surface = Rubygame::Surface.new([10,10])
  end

  it "should default to 1.0" do
    @surface.opacity.should eql( 1.0 )
  end

  context "given an argument" do
    it "should return self" do
      @surface.opacity(0.5).should equal( @surface )
    end

    it "should set opacity" do
      @surface.opacity(0.5)
      @surface.opacity.should eql( 0.5 )
    end

    it "should clamp floats less than 0.0" do
      @surface.opacity(-1.0)
      @surface.opacity.should eql( 0.0 )
    end

    it "should clamp floats greater than 1.0" do
      @surface.opacity(0.0)
      @surface.opacity(2.0)
      @surface.opacity.should eql( 1.0 )
    end

    it "should convert integers to floats" do
      @surface.opacity(-1)
      @surface.opacity.should eql( 0.0 )
      @surface.opacity(0)
      @surface.opacity.should eql( 0.0 )
      @surface.opacity(1)
      @surface.opacity.should eql( 1.0 )
      @surface.opacity(2)
      @surface.opacity.should eql( 1.0 )
    end

    invalid_args = {
      "true"        => true,
      "a symbol"    => :symbol,
      "an array"    => [1.0],
      "a hash"      => {1=>2},
      "some object" => Object.new,
    }

    invalid_args.each do |thing, arg|
      it "should fail when given #{thing}" do
        expect{@surface.opacity(arg)}.to raise_error
      end
    end
  end

end


describe Surface, "#opacity=" do

  before :each do
    @surface = Rubygame::Surface.new([10,10])
  end

  it "should set opacity" do
    @surface.opacity = 0.5
    @surface.opacity.should eql( 0.5 )
  end

  it "should clamp floats less than 0.0" do
    @surface.opacity = -1.0
    @surface.opacity.should eql( 0.0 )
  end

  it "should clamp floats greater than 1.0" do
    @surface.opacity = 0.0
    @surface.opacity = 2.0
    @surface.opacity.should eql( 1.0 )
  end

  it "should convert integers to floats" do
    @surface.opacity = -1
    @surface.opacity.should eql( 0.0 )
    @surface.opacity = 0
    @surface.opacity.should eql( 0.0 )
    @surface.opacity = 1
    @surface.opacity.should eql( 1.0 )
    @surface.opacity = 2
    @surface.opacity.should eql( 1.0 )
  end

  invalid_args = {
    "true"        => true,
    "a symbol"    => :symbol,
    "an array"    => [1.0],
    "a hash"      => {1=>2},
    "some object" => Object.new,
  }

  invalid_args.each do |thing, arg|
    it "should fail when given #{thing}" do
      expect{@surface.opacity = arg}.to raise_error
    end
  end
end



describe Surface, "colorkey" do

  before :each do
    @surface = Rubygame::Surface.new([10,10])
  end

  it "should be nil by default" do
    @surface.colorkey.should be_nil
  end

  it "should return colors as [R,G,B] (0-255)" do
    @surface.colorkey = :sky_blue
    @surface.colorkey.should == [135, 206, 235]
  end

  context "given an arg" do
    it "should set the colorkey" do
      @surface.colorkey( [135, 206, 235] )
      @surface.colorkey.should == [135, 206, 235]
    end

    it "should accept a [R,G,B] array" do
      @surface.colorkey( [135, 206, 235] )
      @surface.colorkey.should == [135, 206, 235]
    end

    it "should accept a [R,G,B,A] array but ignore alpha" do
      @surface.colorkey( [135, 206, 235, 128] )
      @surface.colorkey.should == [135, 206, 235]
    end

    it "should accept a color name symbol" do
      @surface.colorkey( :sky_blue )
      @surface.colorkey.should == [135, 206, 235]
    end

    it "should accept a color name string" do
      @surface.colorkey( "sky_blue" )
      @surface.colorkey.should == [135, 206, 235]
    end

    it "should accept a hex color string" do
      @surface.colorkey( "#87ceeb" )
      @surface.colorkey.should == [135, 206, 235]
    end

    it "should accept a Color" do
      @surface.colorkey( Rubygame::Color[:sky_blue] )
      @surface.colorkey.should == [135, 206, 235]
    end

    it "should accept nil" do
      @surface.colorkey( nil )
      @surface.colorkey.should be_nil
    end

    invalid_args = {
      "true"          => true,
      "false"         => false,
      "a short array" => [1.0],
      "a hash"        => {1=>2},
      "some object"   => Object.new,
    }

    invalid_args.each do |thing, arg|
      it "should fail when given #{thing}" do
        expect{@surface.colorkey(arg)}.to raise_error
      end
    end
  end

  context "writer" do
    it "should set the colorkey" do
      @surface.colorkey = [135, 206, 235]
      @surface.colorkey.should == [135, 206, 235]
    end

    it "should accept a [R,G,B] array" do
      @surface.colorkey = [135, 206, 235]
      @surface.colorkey.should == [135, 206, 235]
    end

    it "should accept a [R,G,B,A] array but ignore alpha" do
      @surface.colorkey = [135, 206, 235, 128]
      @surface.colorkey.should == [135, 206, 235]
    end

    it "should accept a color name symbol" do
      @surface.colorkey = :sky_blue
      @surface.colorkey.should == [135, 206, 235]
    end

    it "should accept a color name string" do
      @surface.colorkey = "sky_blue"
      @surface.colorkey.should == [135, 206, 235]
    end

    it "should accept a hex color string" do
      @surface.colorkey = "#87ceeb"
      @surface.colorkey.should == [135, 206, 235]
    end

    it "should accept a Color" do
      @surface.colorkey = Rubygame::Color[:sky_blue]
      @surface.colorkey.should == [135, 206, 235]
    end

    it "should accept nil" do
      @surface.colorkey = nil
      @surface.colorkey.should be_nil
    end

    invalid_args = {
      "true"          => true,
      "false"         => false,
      "a short array" => [1.0],
      "a hash"        => {1=>2},
      "some object"   => Object.new,
    }

    invalid_args.each do |thing, arg|
      it "should fail when given #{thing}" do
        expect{@surface.colorkey = arg}.to raise_error
      end
    end
  end

end


describe Surface, "set_colorkey" do
  before :each do
    @surface = Rubygame::Surface.new([10,10])
  end

  it "should set the colorkey" do
    @surface.set_colorkey( [135, 206, 235] )
    @surface.colorkey.should == [135, 206, 235]
  end

  it "should accept a [R,G,B] array" do
    @surface.set_colorkey( [135, 206, 235] )
    @surface.colorkey.should == [135, 206, 235]
  end

  it "should accept a [R,G,B,A] array but ignore alpha" do
    @surface.set_colorkey( [135, 206, 235, 128] )
    @surface.colorkey.should == [135, 206, 235]
  end

  it "should accept a color name symbol" do
    @surface.set_colorkey( :sky_blue )
    @surface.colorkey.should == [135, 206, 235]
  end

  it "should accept a color name string" do
    @surface.set_colorkey( "sky_blue" )
    @surface.colorkey.should == [135, 206, 235]
  end

  it "should accept a hex color string" do
    @surface.set_colorkey( "#87ceeb" )
    @surface.colorkey.should == [135, 206, 235]
  end

  it "should accept a Color" do
    @surface.set_colorkey( Rubygame::Color[:sky_blue] )
    @surface.colorkey.should == [135, 206, 235]
  end

  it "should accept nil" do
    @surface.set_colorkey( nil )
    @surface.colorkey.should be_nil
  end
end



describe Surface, "#to_opengl" do

  context "with an 8-bit Surface" do
    before :each do
      @surface = Surface.new([2,2], :depth => 8)
      @surface.palette = [[10,20,30],[40,50,60],[70,80,90],[100,110,120]]
      @surface.set_at([0,0], [ 10, 20, 30])
      @surface.set_at([1,0], [ 40, 50, 60])
      @surface.set_at([0,1], [ 70, 80, 90])
      @surface.set_at([1,1], [100,110,120])
    end

    it ":type should be GL_UNSIGNED_BYTE (5121)" do
      @surface.to_opengl[:type].should == 5121
    end

    it ":format should be GL_RGB (6407)" do
      @surface.to_opengl[:format].should == 6407
    end

    it ":data should match expected" do
      # 24-bit RGB format.
      expected =
        #  10  20  30       40  50  60    padding
        "\x0a\x14\x1e" + "\x28\x32\x3c" + "\x0\x0" +
        #  70  80  90      100 110 120    padding
        "\x46\x50\x5a" + "\x64\x6e\x78" + "\x0\x0"
      @surface.to_opengl[:data].should == expected
    end
  end


  context "with a 15-bit RGB Surface" do
    before :each do
      masks = [0x007c00,  0x0003e0,  0x00001f, 0]
      @surface = Surface.new([2,2], :depth => 15, :masks => masks)
      @surface.set_at([0,0], [ 10, 20, 30])
      @surface.set_at([1,0], [ 40, 50, 60])
      @surface.set_at([0,1], [ 70, 80, 90])
      @surface.set_at([1,1], [100,110,120])
    end

    it ":type should be GL_UNSIGNED_BYTE (5121)" do
      @surface.to_opengl[:type].should == 5121
    end

    it ":format should be GL_RGB (6407)" do
      @surface.to_opengl[:format].should == 6407
    end

    it ":data should match expected" do
      # 24-bit RGB format. Note: 15-bit color format is lossy.
      expected =
        #   8  16  24       40  48  56    padding
        "\x08\x10\x18" + "\x28\x30\x38" + "\x0\x0" +
        #  64  80  88       96 104 120    padding
        "\x40\x50\x58" + "\x60\x68\x78" + "\x0\x0"
      @surface.to_opengl[:data].should == expected
    end
  end

  context "with a 15-bit BGR Surface" do
    before :each do
      masks = [0x00001f,  0x0003e0,  0x007c00, 0]
      @surface = Surface.new([2,2], :depth => 15, :masks => masks)
      @surface.set_at([0,0], [ 10, 20, 30])
      @surface.set_at([1,0], [ 40, 50, 60])
      @surface.set_at([0,1], [ 70, 80, 90])
      @surface.set_at([1,1], [100,110,120])
    end

    it ":type should be GL_UNSIGNED_BYTE (5121)" do
      @surface.to_opengl[:type].should == 5121
    end

    it ":format should be GL_RGB (6407)" do
      @surface.to_opengl[:format].should == 6407
    end

    it ":data should be in 24-bit RGB format" do
      # 24-bit RGB format. Note: 15-bit color format is lossy.
      expected =
        #   8  16  24       40  48  56    padding
        "\x08\x10\x18" + "\x28\x30\x38" + "\x0\x0" +
        #  64  80  88       96 104 120    padding
        "\x40\x50\x58" + "\x60\x68\x78" + "\x0\x0"
      @surface.to_opengl[:data].should == expected
    end
  end


  context "with a 16-bit RGB Surface" do
    before :each do
      masks = [0x00f800,  0x0007e0,  0x00001f, 0]
      @surface = Surface.new([2,2], :depth => 16, :masks => masks)
      @surface.set_at([0,0], [ 10, 20, 30])
      @surface.set_at([1,0], [ 40, 50, 60])
      @surface.set_at([0,1], [ 70, 80, 90])
      @surface.set_at([1,1], [100,110,120])
    end

    it ":type should be GL_UNSIGNED_BYTE (5121)" do
      @surface.to_opengl[:type].should == 5121
    end

    it ":format should be GL_RGB (6407)" do
      @surface.to_opengl[:format].should == 6407
    end

    it ":data should match expected" do
      # 24-bit RGB format. Note: 16-bit color format is lossy.
      expected =
        #   8  20  24       40  48  56    padding
        "\x08\x14\x18" + "\x28\x30\x38" + "\x0\x0" +
        #  64  80  88       96 108 120    padding
        "\x40\x50\x58" + "\x60\x6c\x78" + "\x0\x0"
      @surface.to_opengl[:data].should == expected
    end
  end

  context "with a 16-bit BGR Surface" do
    before :each do
      masks = [0x00001f,  0x0007e0,  0x00f800, 0]
      @surface = Surface.new([2,2], :depth => 16, :masks => masks)
      @surface.set_at([0,0], [ 10, 20, 30])
      @surface.set_at([1,0], [ 40, 50, 60])
      @surface.set_at([0,1], [ 70, 80, 90])
      @surface.set_at([1,1], [100,110,120])
    end

    it ":type should be GL_UNSIGNED_BYTE (5121)" do
      @surface.to_opengl[:type].should == 5121
    end

    it ":format should be GL_RGB (6407)" do
      @surface.to_opengl[:format].should == 6407
    end

    it ":data should match expected" do
      # 24-bit RGB format. Note: 16-bit color format is lossy.
      expected =
        #   8  20  24       40  48  56    padding
        "\x08\x14\x18" + "\x28\x30\x38" + "\x0\x0" +
        #  64  80  88       96 108 120    padding
        "\x40\x50\x58" + "\x60\x6c\x78" + "\x0\x0"
      @surface.to_opengl[:data].should == expected
    end
  end


  context "with a 24-bit RGB Surface" do
    before :each do
      masks = [0xff << 16, 0xff << 8, 0xff << 0, 0]
      @surface = Surface.new([2,2], :depth => 24, :masks => masks)
      @surface.set_at([0,0], [ 10, 20, 30])
      @surface.set_at([1,0], [ 40, 50, 60])
      @surface.set_at([0,1], [ 70, 80, 90])
      @surface.set_at([1,1], [100,110,120])
    end

    it ":type should be GL_UNSIGNED_BYTE (5121)" do
      @surface.to_opengl[:type].should == 5121
    end

    it ":format should be GL_RGB (6407)" do
      @surface.to_opengl[:format].should == 6407
    end

    it ":data should match expected" do
      # 24-bit RGB format
      expected =
        #  10  20  30       40  50  60    padding
        "\x0a\x14\x1e" + "\x28\x32\x3c" + "\x0\x0" +
        #  70  80  90      100 110 120    padding
        "\x46\x50\x5a" + "\x64\x6e\x78" + "\x0\x0"
      @surface.to_opengl[:data].should == expected
    end
  end

  context "with a 24-bit BGR Surface" do
    before :each do
      masks = [0xff << 0, 0xff << 8, 0xff << 16, 0]
      @surface = Surface.new([2,2], :depth => 24, :masks => masks)
      @surface.set_at([0,0], [ 10, 20, 30])
      @surface.set_at([1,0], [ 40, 50, 60])
      @surface.set_at([0,1], [ 70, 80, 90])
      @surface.set_at([1,1], [100,110,120])
    end

    it ":type should be GL_UNSIGNED_BYTE (5121)" do
      @surface.to_opengl[:type].should == 5121
    end

    it ":format should be GL_RGB (6407)" do
      @surface.to_opengl[:format].should == 6407
    end

    it ":data should match expected" do
      # 24-bit RGB format.
      expected =
        #  10  20  30       40  50  60    padding
        "\x0a\x14\x1e" + "\x28\x32\x3c" + "\x0\x0" +
        #  70  80  90      100 110 120    padding
        "\x46\x50\x5a" + "\x64\x6e\x78" + "\x0\x0"
      @surface.to_opengl[:data].should == expected
    end
  end


  context "with a 32-bit RGB Surface" do
    before :each do
      masks = [0xff << 16, 0xff << 8, 0xff << 0, 0]
      @surface = Surface.new([2,2], :depth => 32, :masks => masks)
      @surface.set_at([0,0], [ 10, 20, 30])
      @surface.set_at([1,0], [ 40, 50, 60])
      @surface.set_at([0,1], [ 70, 80, 90])
      @surface.set_at([1,1], [100,110,120])
    end

    it ":type should be GL_UNSIGNED_BYTE (5121)" do
      @surface.to_opengl[:type].should == 5121
    end

    it ":format should be GL_RGB (6407)" do
      @surface.to_opengl[:format].should == 6407
    end

    it ":data should match expected" do
      # 24-bit RGB format.
      expected =
        #  10  20  30       40  50  60    padding
        "\x0a\x14\x1e" + "\x28\x32\x3c" + "\x0\x0" +
        #  70  80  90      100 110 120    padding
        "\x46\x50\x5a" + "\x64\x6e\x78" + "\x0\x0"
      @surface.to_opengl[:data].should == expected
    end
  end

  context "with a 32-bit BGR Surface" do
    before :each do
      masks = [0xff << 0, 0xff << 8, 0xff << 16, 0]
      @surface = Surface.new([2,2], :depth => 32, :masks => masks)
      @surface.set_at([0,0], [ 10, 20, 30])
      @surface.set_at([1,0], [ 40, 50, 60])
      @surface.set_at([0,1], [ 70, 80, 90])
      @surface.set_at([1,1], [100,110,120])
    end

    it ":type should be GL_UNSIGNED_BYTE (5121)" do
      @surface.to_opengl[:type].should == 5121
    end

    it ":format should be GL_RGB (6407)" do
      @surface.to_opengl[:format].should == 6407
    end

    it ":data should match expected" do
      # 24-bit RGB format.
      expected =
        #  10  20  30       40  50  60    padding
        "\x0a\x14\x1e" + "\x28\x32\x3c" + "\x0\x0" +
        #  70  80  90      100 110 120    padding
        "\x46\x50\x5a" + "\x64\x6e\x78" + "\x0\x0"
      @surface.to_opengl[:data].should == expected
    end
  end


  context "with a 32-bit RGBA Surface" do
    before :each do
      masks = [0xff << 16, 0xff << 8, 0xff << 0, 0xff << 24]
      @surface = Surface.new([2,2], :depth => 32, :masks => masks, :alpha => true)
      @surface.set_at([0,0], [ 10, 20, 30, 40])
      @surface.set_at([1,0], [ 50, 60, 70, 80])
      @surface.set_at([0,1], [ 90,100,110,120])
      @surface.set_at([1,1], [130,140,150,160])
    end

    it ":type should be GL_UNSIGNED_BYTE (5121)" do
      @surface.to_opengl[:type].should == 5121
    end

    it ":format should be GL_RGBA (6408)" do
      @surface.to_opengl[:format].should == 6408
    end

    it ":data should match expected" do
      # 32-bit RGBA format.
      expected =
        #  10  20  30  40       50  60  70  80
        "\x0a\x14\x1e\x28" + "\x32\x3c\x46\x50" +
        #  90 100 110 120      130 140 150 160
        "\x5a\x64\x6e\x78" + "\x82\x8c\x96\xa0"
      @surface.to_opengl[:data].should == expected
    end
  end

  context "with a 32-bit BGRA Surface" do
    before :each do
      masks = [0xff << 0, 0xff << 8, 0xff << 16, 0xff << 24]
      @surface = Surface.new([2,2], :depth => 32, :masks => masks, :alpha => true)
      @surface.set_at([0,0], [ 10, 20, 30, 40])
      @surface.set_at([1,0], [ 50, 60, 70, 80])
      @surface.set_at([0,1], [ 90,100,110,120])
      @surface.set_at([1,1], [130,140,150,160])
    end

    it ":type should be GL_UNSIGNED_BYTE (5121)" do
      @surface.to_opengl[:type].should == 5121
    end

    it ":format should be GL_RGBA (6408)" do
      @surface.to_opengl[:format].should == 6408
    end

    it ":data should match expected" do
      # 32-bit RGBA format.
      expected =
        #  10  20  30  40       50  60  70  80
        "\x0a\x14\x1e\x28" + "\x32\x3c\x46\x50" +
        #  90 100 110 120      130 140 150 160
        "\x5a\x64\x6e\x78" + "\x82\x8c\x96\xa0"
      @surface.to_opengl[:data].should == expected
    end
  end


  context "with a flat Surface with a colorkey" do
    before :each do
      @surface = Surface.new([2,2], :depth => 24, :colorkey => [40,50,60])
      @surface.set_at([0,0], [ 10, 20, 30])
      @surface.set_at([1,0], [ 40, 50, 60])
      @surface.set_at([0,1], [ 70, 80, 90])
      @surface.set_at([1,1], [100,110,120])
    end

    it ":type should be GL_UNSIGNED_BYTE (5121)" do
      @surface.to_opengl[:type].should == 5121
    end

    it ":format should be GL_RGBA (6408)" do
      @surface.to_opengl[:format].should == 6408
    end

    it ":data should match expected" do
      # 32-bit RGBA, non-colorkey pixels are fully opaque, colorkey
      # pixels are transparent black.
      expected =
        #  10  20  30 255        0   0   0   0
        "\x0a\x14\x1e\xff" + "\x00\x00\x00\x00" +
        #  70  80  90 255      100 110 120 255
        "\x46\x50\x5a\xff" + "\x64\x6e\x78\xff"

      @surface.to_opengl[:data].should == expected
    end
  end

  context "with a non-flat Surface with a colorkey" do
    before :each do
      @surface = Surface.new([2,2], :alpha => true, :colorkey => [50,60,70])
      @surface.set_at([0,0], [ 10, 20, 30, 40])
      @surface.set_at([1,0], [ 50, 60, 70, 80])
      @surface.set_at([0,1], [ 90,100,110,120])
      @surface.set_at([1,1], [130,140,150,160])
    end

    it ":type should be GL_UNSIGNED_BYTE (5121)" do
      @surface.to_opengl[:type].should == 5121
    end

    it ":format should be GL_RGBA (6408)" do
      @surface.to_opengl[:format].should == 6408
    end

    it ":data should match expected" do
      # 32-bit RGBA, alpha channel is preserved on non-colorkey
      # pixels, but colorkey pixels become transparent black.
      expected =
        #  10  20  30  40        0   0   0   0
        "\x0a\x14\x1e\x28" + "\x00\x00\x00\x00" +
        #  90 100 110 120      130 140 150 160
        "\x5a\x64\x6e\x78" + "\x82\x8c\x96\xa0"
      @surface.to_opengl[:data].should == expected
    end
  end


  context "with a flat Surface with opacity" do
    before :each do
      @surface = Surface.new([2,2], :depth => 24, :opacity => 0.5)
      @surface.set_at([0,0], [ 10, 20, 30])
      @surface.set_at([1,0], [ 40, 50, 60])
      @surface.set_at([0,1], [ 70, 80, 90])
      @surface.set_at([1,1], [100,110,120])
    end

    it ":type should be GL_UNSIGNED_BYTE (5121)" do
      @surface.to_opengl[:type].should == 5121
    end

    it ":format should be GL_RGBA (6408)" do
      @surface.to_opengl[:format].should == 6408
    end

    it ":data should match expected" do
      # 32-bit RGBA, opacity becomes alpha channel.
      expected =
        #  10  20  30 127       40  50  60 127 
        "\x0a\x14\x1e\x7f" + "\x28\x32\x3c\x7f" +
        #  70  80  90 127      100 110 120 127
        "\x46\x50\x5a\x7f" + "\x64\x6e\x78\x7f"
      @surface.to_opengl[:data].should == expected
    end
  end

  context "with a non-flat Surface with opacity" do
    before :each do
      @surface = Surface.new([2,2], :alpha => true, :opacity => 0.5)
      @surface.set_at([0,0], [ 10, 20, 30, 40])
      @surface.set_at([1,0], [ 50, 60, 70, 80])
      @surface.set_at([0,1], [ 90,100,110,120])
      @surface.set_at([1,1], [130,140,150,160])
    end

    it ":type should be GL_UNSIGNED_BYTE (5121)" do
      @surface.to_opengl[:type].should == 5121
    end

    it ":format should be GL_RGBA (6408)" do
      @surface.to_opengl[:format].should == 6408
    end

    it ":data should match expected" do
      # In SDL, alpha channel is not affected by opacity.
      expected =
        #  10  20  30  40       50  60  70  80
        "\x0a\x14\x1e\x28" + "\x32\x3c\x46\x50" +
        #  90 100 110 120      130 140 150 160
        "\x5a\x64\x6e\x78" + "\x82\x8c\x96\xa0"
      @surface.to_opengl[:data].should == expected
    end
  end

end



describe Surface, "#[]" do

  shared_examples_for "#[] method" do
    it "should raise IndexError if x < 0" do
      expect{ @surface[-1,0] }.to raise_error(IndexError)
    end

    it "should raise IndexError if x == w" do
      expect{ @surface[@surface.w,0] }.to raise_error(IndexError)
    end

    it "should raise IndexError if x > w" do
      expect{ @surface[@surface.w+1,0] }.to raise_error(IndexError)
    end

    it "should raise IndexError if y < 0" do
      expect{ @surface[0,-1] }.to raise_error(IndexError)
    end

    it "should raise IndexError if y == h" do
      expect{ @surface[0,@surface.h] }.to raise_error(IndexError)
    end

    it "should raise IndexError if y > h" do
      expect{ @surface[0,@surface.h+1] }.to raise_error(IndexError)
    end


    it "should not raise error at [0,0]" do
      expect{ @surface[0,0] }.not_to raise_error
    end

    it "should not raise error at [w-1,0]" do
      expect{ @surface[@surface.w-1,0] }.not_to raise_error
    end

    it "should not raise error at [0,h-1]" do
      expect{ @surface[0,@surface.h-1] }.not_to raise_error
    end

    it "should not raise error at [w-1,h-1]" do
      expect{ @surface[@surface.w-1,@surface.h-1] }.not_to raise_error
    end


    it "should raise error if given no args" do
      expect{ @surface[] }.to raise_error(ArgumentError)
    end

    it "should raise error if given only one arg" do
      expect{ @surface[0] }.to raise_error(ArgumentError)
    end

    it "should raise error if given too many args" do
      expect{ @surface[0,0,0] }.to raise_error(ArgumentError)
    end

    invalid_args = {
      "true"        => true,
      "false"       => false,
      "nil"         => nil,
      "a string"    => "str",
      "a symbol"    => :sym,
      "an array"    => [1,2],
      "a hash"      => {1=>2},
      "some object" => Object.new,
    }

    invalid_args.each do |thing, arg|
      it "should raise TypeError if given #{thing}" do
        expect{ @surface[arg,0] }.to raise_error
      end
    end

    it "should not raise error if given floats" do
      expect{ @surface[0.3,1.2] }.not_to raise_error
    end
  end


  context "with palettized Surface" do
    before :each do
      @surface = Surface.new([2,2], :depth => 8)
      @surface.palette = [[255,0,0],[0,255,0],[0,0,255],[255,255,255]]
      @surface.fill([255,  0,  0], [0,0,1,1])
      @surface.fill([  0,255,  0], [1,0,1,1])
      @surface.fill([  0,  0,255], [0,1,1,1])
      @surface.fill([255,255,255], [1,1,1,1])
    end

    it_should_behave_like "#[] method"

    it "should be slot 0 at [0,0]" do
      @surface[0,0].should eql( @surface.palette[0] )
    end

    it "slot color should be ColorRGB255 [255,0,0] at [0,0]" do
      @surface[0,0].color.should eql( Color.rgb255([255,0,0]) )
    end

    it "should be slot 1 at [1,0]" do
      @surface[1,0].should eql( @surface.palette[1] )
    end

    it "slot color should be ColorRGB255 [0,255,0] at [1,0]" do
      @surface[1,0].color.should eql( Color.rgb255([0,255,0]) )
    end

    it "should be slot 2 at [0,1]" do
      @surface[0,1].should eql( @surface.palette[2] )
    end

    it "slot color should be ColorRGB255 [0,0,255] at [0,1]" do
      @surface[0,1].color.should eql( Color.rgb255([0,0,255]) )
    end

    it "should be slot 3 at [1,1]" do
      @surface[1,1].should eql( @surface.palette[3] )
    end

    it "slot color should be ColorRGB255 [255,255,255] at [1,1]" do
      @surface[1,1].color.should eql( Color.rgb255([255,255,255]) )
    end
  end


  [15, 16, 24, 32].each do |depth|
    context "with #{depth}-bit Surface" do
      before :each do
        @surface = Surface.new([2,2], :depth => depth)
        @surface.fill([255,  0,  0], [0,0,1,1])
        @surface.fill([  0,255,  0], [1,0,1,1])
        @surface.fill([  0,  0,255], [0,1,1,1])
        @surface.fill([255,255,255], [1,1,1,1])
      end

      it_should_behave_like "#[] method"

      it "should be ColorRGB255 [255,0,0] at [0,0]" do
        @surface[0,0].should eql( Color.rgb255([255,0,0]) )
      end

      it "should be ColorRGB255 [0,255,0] at [1,0]" do
        @surface[1,0].should eql( Color.rgb255([0,255,0]) )
      end

      it "should be ColorRGB255 [0,0,255] at [0,1]" do
        @surface[0,1].should eql( Color.rgb255([0,0,255]) )
      end

      it "should be ColorRGB255 [255,255,255] at [1,1]" do
        @surface[1,1].should eql( Color.rgb255([255,255,255]) )
      end
    end
  end

end
