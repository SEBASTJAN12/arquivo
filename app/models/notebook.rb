class Notebook < ApplicationRecord
  has_many :calendar_imports, foreign_key: :notebook, primary_key: :name
  has_many :entries, foreign_key: :notebook, primary_key: :name
  has_many :links
  has_many :tags, foreign_key: :notebook, primary_key: :name
  has_many :contacts, foreign_key: :notebook, primary_key: :name
  has_many :saved_searches, foreign_key: :notebook, primary_key: :name

  has_many :sync_states, dependent: :delete_all

  after_create :initialize_git
  attr_accessor :skip_local_sync

  def self.for(name)
    self.find_by(name: name)
  end

  def self.default
    "journal"
  end

  # not actually tested or used often
  def self.create_from_remote(name, remote)
    notebook = self.create(name: name, skip_local_sync: true)
    SyncWithGit.new(notebook).clone(remote)
  end

  def push_to_git!
    SyncWithGit.new(self).push! unless Arquivo.static?
  end

  def pull_from_git!
    SyncWithGit.new(self).pull! unless Arquivo.static?
  end

  def sync_git_settings!
    SyncWithGit.new(self).setup_git_remote_and_key! unless Arquivo.static?
  end

  def to_s
    name
  end

  def to_param
    name
  end

  def name_with_owner
    "#{owner}/#{self}"
  end

  def cast_twz_to_time(hash)
    hash.reduce({}) do |h, (k,v)|
      if v.is_a?(ActiveSupport::TimeWithZone)
        h[k] = v.to_time
      else
        h[k] = v
      end

      h
    end
  end

  # TODO: TEST THAT WE DON'T EXPORT THIS OR BETTER YET MOVE THE KEYS TO A DIFFERENT TABLE
  def export_attributes
    self.attributes.except("id", "remote", "private_key")
  end

  def to_yaml
    cast_twz_to_time(export_attributes).to_yaml
  end

  def to_folder_path(path = nil)
    # if we do not supply a path, first check to see if we stored a a notebook
    # path on import. If we did not, then let's go ahead and use the system
    # default arquivo path
    if self.import_path
      return import_path
    else
      path ||= Setting.get(:arquivo, :arquivo_path)

      File.join(path, "notebooks", self.to_s)
    end
  end

  def to_full_file_path(path = nil)
    path ||= Setting.get(:arquivo, :arquivo_path)
    File.join(to_folder_path(path), "notebook.yaml")
  end

  def initialize_git
    unless self.skip_local_sync || Rails.application.config.skip_local_sync || Arquivo.static?
      SyncToDisk.new(self).write_notebook_file
      syncer = SyncWithGit.new(self)
      syncer.init!
    end
  end

  def owner
    @owner ||= User.current
  end

  def title
    @title ||= self.entries.find_by(identifier: "_title")
  end

  def description
    @description ||= self.entries.find_by(identifier: "_description")
  end

  def settings
    @settings ||= NotebookSettings.new(self)
  end
end
