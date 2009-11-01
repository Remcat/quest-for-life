require 'spec/spec_helper'

describe ActiveHash, "Base" do

  before do
    class Country < ActiveHash::Base
    end
  end

  after do
    Object.send :remove_const, :Country
  end

  describe ".fields" do
    before do
      Country.fields :name, :iso_name
    end

    it "defines a reader for each field" do
      Country.new.should respond_to(:name)
      Country.new.should respond_to(:iso_name)
    end

    it "defines interrogator methods for each field" do
      Country.new.should respond_to(:name?)
      Country.new.should respond_to(:iso_name?)
    end

    it "defines single finder methods for each field" do
      Country.should respond_to(:find_by_name)
      Country.should respond_to(:find_by_iso_name)
    end

    it "defines array finder methods for each field" do
      Country.should respond_to(:find_all_by_name)
      Country.should respond_to(:find_all_by_iso_name)
    end

    it "defines single finder methods for all combinations of fields" do
      Country.should respond_to(:find_by_name_and_iso_name)
      Country.should respond_to(:find_by_iso_name_and_name)
    end

    it "defines array finder methods for all combinations of fields" do
      Country.should respond_to(:find_all_by_name_and_iso_name)
      Country.should respond_to(:find_all_by_iso_name_and_name)
    end
  end

  describe ".data=" do
    before do
      class Region < ActiveHash::Base
        field :description
      end
    end

    it "populates the object with data" do
      Country.data = [{:name => "US"}, {:name => "Canada"}]
      Country.data.should == [{:name => "US"}, {:name => "Canada"}]
    end

    it "allows each of it's subclasses to have it's own data" do
      Country.data = [{:name => "US"}, {:name => "Canada"}]
      Region.data = [{:description => "A big region"}, {:description => "A remote region"}]

      Country.data.should == [{:name => "US"}, {:name => "Canada"}]
      Region.data.should == [{:description => "A big region"}, {:description => "A remote region"}]
    end
  end

  describe ".all" do
    before do
      Country.field :name
      Country.data = [
        {:id => 1, :name => "US"},
        {:id => 2, :name => "Canada"}
      ]
    end

    it "returns an empty array if data is nil" do
      Country.data = nil
      Country.all.should be_empty
    end

    it "returns all data as inflated objects" do
      Country.all.all?{|country| country.should be_kind_of(Country)}
    end

    it "populates the data correctly" do
      records = Country.all
      records.first.id.should == 1
      records.first.name.should == "US"
      records.last.id.should == 2
      records.last.name.should == "Canada"
    end

    it "re-populates the records after data= is called" do
      Country.data = [
        {:id => 45, :name => "Canada"}
      ]
      records = Country.all
      records.first.id.should == 45
      records.first.name.should == "Canada"
      records.length.should == 1
    end
  end

  describe ".count" do
    before do
      Country.data = [
        {:id => 1, :name => "US"},
        {:id => 2, :name => "Canada"}
      ]
    end

    it "returns the number of elements in the array" do
      Country.count.should == 2
    end
  end

  describe ".first" do
    before do
      Country.data = [
        {:id => 1, :name => "US"},
        {:id => 2, :name => "Canada"}
      ]
    end

    it "returns the first object" do
      Country.first.should == Country.new(:id => 1)
    end
  end

  describe ".last" do
    before do
      Country.data = [
        {:id => 1, :name => "US"},
        {:id => 2, :name => "Canada"}
      ]
    end

    it "returns the last object" do
      Country.last.should == Country.new(:id => 2)
    end
  end

  describe ".find" do
    before do
      Country.data = [
        {:id => 1, :name => "US"},
        {:id => 2, :name => "Canada"}
      ]
    end

    context "with an id" do
      it "finds the record with the specified id" do
        Country.find(2).id.should == 2
      end

      it "finds the record with the specified id as a string" do
        Country.find("2").id.should == 2
      end
    end

    context "with :all" do
      it "returns all records" do
        Country.find(:all).should =~ [Country.new(:id => 1), Country.new(:id => 2)]
      end
    end

    context "with 2 arguments" do
      it "returns the record with the given id and ignores the conditions" do
        Country.find(1, :conditions => "foo=bar").should == Country.new(:id => 1)
        Country.find(:all, :conditions => "foo=bar").length.should == 2
      end
    end

    context "with an array of ids" do
      before do
        Country.data = [
          {:id => 1},
          {:id => 2},
          {:id => 3}
        ]
      end

      it "returns all matching ids" do
        Country.find([1,3]).should =~ [Country.new(:id => 1), Country.new(:id => 3)]
      end
    end
  end

  describe ".find_by_id" do
    before do
      Country.data = [
        {:id => 1, :name => "US"},
        {:id => 2, :name => "Canada"}
      ]
    end

    context "with an id" do
      it "finds the record with the specified id" do
        Country.find_by_id(2).id.should == 2
      end
    end

    context "with nil" do
      it "returns nil" do
        Country.find_by_id(nil).should be_nil
      end
    end

    context "with an id not present" do
      it "returns nil" do
        Country.find_by_id(4567).should be_nil
      end
    end
  end

  describe "custom finders" do
    before do
      Country.fields :name, :monarch, :language

      # Start ids above 4 lest we get nil and think it's an AH::Base model with id=4.
      Country.data = [
        {:id => 11, :name => nil, :monarch => nil, :language => "Latin"},
        {:id => 12, :name => "US", :monarch => nil, :language => "English"},
        {:id => 13, :name => "Canada", :monarch => "The Crown of England", :language => "English"},
        {:id => 14, :name => "UK", :monarch => "The Crown of England", :language => "English"}
      ]
    end

    describe "find_by_<field_name>" do
      describe "with a match" do
        context "for a non-nil argument" do
          it "returns the first matching record" do
            Country.find_by_name("US").id.should == 12
          end
        end

        context "for a nil argument" do
          it "returns the first matching record" do
            Country.find_by_name(nil).id.should == 11
          end
        end
      end

      describe "without a match" do
        before do
          Country.data = []
        end

        context "for a non-nil argument" do
          it "returns nil" do
            Country.find_by_name("Mexico").should be_nil
          end
        end

        context "for a nil argument" do
          it "returns nil" do
            Country.find_by_name(nil).should be_nil
          end
        end
      end
    end

    describe "find_all_by_<field_name>" do
      describe "with matches" do
        it "returns all matching records" do
          countries = Country.find_all_by_monarch("The Crown of England")
          countries.length.should == 2
          countries.first.name.should == "Canada"
          countries.last.name.should == "UK"
        end
      end

      describe "without matches" do
        it "returns an empty array" do
          Country.find_all_by_name("Mexico").should be_empty
        end
      end
    end

    describe "find_by_<field_one>_and_<field_two>" do
      describe "with a match" do
        it "returns the first matching record" do
          Country.find_by_name_and_monarch("Canada", "The Crown of England").id.should == 13
          Country.find_by_monarch_and_name("The Crown of England", "Canada").id.should == 13
        end
      end

      describe "without a match" do
        it "returns nil" do
          Country.find_by_name_and_monarch("US", "The Crown of England").should be_nil
        end
      end

      describe "for fields the class doesn't have" do
        it "raises a NoMethodError" do
          lambda {
            Country.find_by_name_and_shoe_size("US", 10)
          }.should raise_error(NoMethodError, "undefined method `find_by_name_and_shoe_size' for Country:Class")
        end
      end
    end

    describe "find_all_by_<field_one>_and_<field_two>" do
      describe "with matches" do
        it "returns all matching records" do
          countries = Country.find_all_by_monarch_and_language("The Crown of England", "English")
          countries.length.should == 2
          countries.first.name.should == "Canada"
          countries.last.name.should == "UK"
        end
      end

      describe "without matches" do
        it "returns an empty array" do
          Country.find_all_by_monarch_and_language("Shaka Zulu", "Zulu").should be_empty
        end
      end
    end
  end


  describe "#attributes" do
    it "returns the hash passed in the initializer" do
      country = Country.new(:foo => :bar)
      country.attributes.should == {:foo => :bar}
    end

    it "symbolizes keys" do
      country = Country.new("foo" => :bar)
      country.attributes.should == {:foo => :bar}
    end
  end

  describe "reader methods" do
    context "for regular fields" do
      before do
        Country.fields :name, :iso_name
      end

      it "returns the given attribute when present" do
        country = Country.new(:name => "Spain")
        country.name.should == "Spain"
      end

      it "returns nil when not present" do
        country = Country.new
        country.name.should be_nil
      end
    end

    context "for fields with default values" do
      before do
        Country.field :name, :default => "foobar"
      end

      it "returns the given attribute when present" do
        country = Country.new(:name => "Spain")
        country.name.should == "Spain"
      end

      it "returns the default value when not present" do
        country = Country.new
        country.name.should == "foobar"
      end
    end
  end

  describe "interrogator methods" do
    before do
      Country.fields :name, :iso_name
    end

    it "returns true if the given attribute is non-blank" do
      country = Country.new(:name => "Spain")
      country.should be_name
    end

    it "returns false if the given attribute is blank" do
      country = Country.new(:name => " ")
      country.should_not be_name
    end

    it "returns false if the given attribute was not passed" do
      country = Country.new
      country.should_not be_name
    end
  end

  describe "#id" do
    context "when passed an id" do
      it "returns the id as an integer" do
        country = Country.new :id => "1"
        country.id.should == 1
      end
    end
    context "when not passed an id" do
      it "returns nil" do
        country = Country.new
        country.id.should be_nil
      end
    end
  end

  describe "#new_record?" do
    it "should be false" do
      Country.new.should_not be_new_record
    end
  end

  describe "#quoted_id" do
    it "should return id" do
      Country.new(:id => 2).quoted_id.should == 2
    end
  end

  describe "#to_param" do
    it "should return id as a string" do
      Country.new(:id => 2).to_param.should == "2"
    end
  end

  describe "#eql?" do
    before do
      class Region < ActiveHash::Base
      end
    end

    it "should return true with the same class and id" do
      Country.new(:id => 23).eql?(Country.new(:id => 23)).should be_true
    end

    it "should return false with the same class and different ids" do
      Country.new(:id => 24).eql?(Country.new(:id => 23)).should be_false
    end

    it "should return false with the different classes and the same id" do
      Country.new(:id => 23).eql?(Region.new(:id => 23)).should be_false
    end

    it "returns false when id is nil" do
      Country.new.eql?(Country.new).should be_false
    end
  end

  describe "#==" do
    before do
      class Region < ActiveHash::Base
      end
    end

    it "should return true with the same class and id" do
      Country.new(:id => 23).should == Country.new(:id => 23)
    end

    it "should return false with the same class and different ids" do
      Country.new(:id => 24).should_not == Country.new(:id => 23)
    end

    it "should return false with the different classes and the same id" do
      Country.new(:id => 23).should_not == Region.new(:id => 23)
    end

    it "returns false when id is nil" do
      Country.new.should_not == Country.new
    end
  end

  describe "#hash" do
    it "returns id for hash" do
      Country.new(:id => 45).hash.should == 45.hash
      Country.new.hash.should == nil.hash
    end

    it "is hashable" do
      { Country.new(:id => 4) => "bar"}.should == {Country.new(:id => 4) => "bar" }
      { Country.new(:id => 3) => "bar"}.should_not == {Country.new(:id => 4) => "bar" }
    end
  end

  describe "#readonly?" do
    it "returns true" do
      Country.new.should be_readonly
    end
  end

  describe "auto-discovery of fields" do
    it "dynamically creates fields for all keys in the hash" do
      Country.data = [
        {:field1 => "foo"},
        {:field2 => "bar"},
        {:field3 => "biz"}
      ]

      Country.all

      [:field1, :field2, :field3].each do |field|
        Country.should respond_to("find_by_#{field}")
        Country.should respond_to("find_all_by_#{field}")
        Country.new.should respond_to(field)
        Country.new.should respond_to("#{field}?")
      end
    end

    it "doesn't override methods already defined" do
      Country.class_eval do
        class << self
          def find_by_name(name)
            "find_by_name defined manually"
          end

          def find_all_by_name(name)
            "find_all_by_name defined manually"
          end
        end

        def name
          "name defined manually"
        end

        def name?
          "name? defined manually"
        end
      end

      Country.data = [
        {:name => "foo"}
      ]

      Country.all
      Country.find_by_name("foo").should == "find_by_name defined manually"
      Country.find_all_by_name("foo").should == "find_all_by_name defined manually"
      Country.new.name.should == "name defined manually"
      Country.new.name?.should == "name? defined manually"
    end
  end

end