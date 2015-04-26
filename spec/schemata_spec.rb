require 'spec_helper'

describe Sequel::Postgres::Schemata do
  
  let(:db) { Sequel::connect adapter: 'postgres', search_path: %w(foo public) } 
  let(:plain_db) { Sequel::connect adapter: 'postgres' }

  describe "#schemata" do
    it "lists all existing schematas" do
      schemata = db.schemata
      schemata.should include(:public)
      schemata.should_not include(:foo)
    end
  end
  
  describe "#search_path" do
    it "returns the search path" do
      db.search_path.should == [:foo, :public]
    end

    it "correctly handles the default list" do
      expect(plain_db.search_path).to eq([:$user, :public])
    end

    describe "with a block" do
      it "changes the search path temporarily" do
        db.search_path :bar do
          db.search_path.should == [:bar]
        end
        db.search_path.should == [:foo, :public]
      end

      it "resets the search path when the given block raises an error" do
        class MyContrivedError < StandardError; end

        begin
          db.search_path :bar do
            db.search_path.should == [:bar]
            raise MyContrivedError.new
          end
        rescue MyContrivedError
          # Gobble.
        end
        db.search_path.should == [:foo, :public]
      end

      it "accepts symbols as arglist" do
        db.search_path :bar, :baz do
          db.search_path.should == [:bar, :baz]
        end
        db.search_path.should == [:foo, :public]
      end

      it "allows prepending with search_path_prepend" do
        db.search_path_prepend :bar do
          db.search_path.should == [:bar, :foo, :public]
        end
        db.search_path.should == [:foo, :public]
      end
    end
  end
  
  describe "#search_path=" do
    it "accepts a single symbol" do
      db.search_path = :bar
      db.search_path.should == [:bar]
    end
    
    it "accepts a single string" do
      db.search_path = 'bar'
      db.search_path.should == [:bar]
    end
    
    it "accepts a formatted string" do
      db.search_path = 'bar, baz'
      db.search_path.should == [:bar, :baz]
    end
    
    it "accepts a symbol list" do
      db.search_path = [:bar, :baz]
      db.search_path.should == [:bar, :baz]
    end
    
    it "accepts a string list" do
      db.search_path = %w(bar baz)
      db.search_path.should == [:bar, :baz]
    end

    it "quotes the string list correctly" do
      db.search_path = ["bar\" ',", "baz"]
      db.search_path.should == [:"bar\" ',", :baz]
    end
  end
  
  describe "#current_schemata" do
    it "returns the current schemata" do
      db.current_schemata.should == [:public]
    end
  end
  
  describe "#rename_schema" do
    it "renames a schema" do
      db.transaction rollback: :always do
        db.create_schema :test_schema
        db.schemata.should include(:test_schema)
        db.current_schemata.should == [:public]
        db.rename_schema :test_schema, :foo
        db.current_schemata.should == [:foo, :public]
      end
    end
  end

end
