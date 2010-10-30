
$:.push(File.dirname(__FILE__) + "/../vendor/lucene/lib")
require 'lucene'

require 'project_search/regex_search_controller'
require 'project_search/word_search_controller'
require 'project_search/lucene_index'
require 'project_search/binary_data_detector'
require 'project_search/commands'

class ProjectSearch
  def self.menus
    Redcar::Menu::Builder.build do
      sub_menu "Project" do
        group :priority => 53 do
          separator
          item "Word Search",  :command => ProjectSearch::WordSearchCommand
          item "Regex Search", :command => ProjectSearch::RegexSearchCommand
        end
      end
    end
  end
  
  def self.keymaps
    osx = Redcar::Keymap.build("main", :osx) do
      link "Cmd+Shift+F",     ProjectSearch::WordSearchCommand
      link "Cmd+Shift+Alt+F", ProjectSearch::RegexSearchCommand
    end
    linwin = Redcar::Keymap.build("main", [:linux, :windows]) do
      link "Ctrl+Shift+F",     ProjectSearch::WordSearchCommand
      link "Ctrl+Shift+Alt+F", ProjectSearch::RegexSearchCommand
    end
    [osx, linwin]
  end

  def self.toolbars
    Redcar::ToolBar::Builder.build do
      item "Project Word Search", :command => WordSearchCommand, 
        :icon => File.join(Redcar::ICONS_DIRECTORY, "application-search-result.png"), 
        :barname => :project
    end
  end

  def self.storage
    @storage ||= begin
      storage = Redcar::Plugin::Storage.new('find_in_project')
      storage.set_default('recent_queries', [])
      storage.set_default('excluded_dirs', ['.git', '.svn', '.redcar'])
      storage.set_default('excluded_files', [])
      storage.set_default('excluded_patterns', [/tags$/, /\.log$/])
      storage.set_default('literal_match', false)
      storage.set_default('match_case', false)
      storage.set_default('with_context', false)
      storage.set_default('context_lines', 2)
      storage.save
    end
  end
  
  Lucene::Config.use do |config| 
    config[:store_on_file] = true 
    config[:storage_path]  = ""
    config[:id_field]      = :id
  end
  
  class LuceneRefresh < Redcar::Task
    def initialize(project)
      @project     = project
    end
    
    def description
      "#{@project.path}: refresh index"
    end
    
    def execute
      return if @project.remote?
      unless index = ProjectSearch.indexes[@project.path]
        index = ProjectSearch::LuceneIndex.new(@project)
        ProjectSearch.indexes[@project.path] = index
      end
      index.update
    end
  end
  
  def self.project_refresh_task_type
    LuceneRefresh
  end
  
  def self.indexes
    @indexes ||= {}
  end
end


