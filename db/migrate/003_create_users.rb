# $Id: 003_create_users.rb 699 2007-01-26 07:52:17Z frumkinj $

# LibraryFind - Quality find done better.
# Copyright (C) 2007 Oregon State University
#
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or (at your option) any later 
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT 
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with 
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple 
# Place, Suite 330, Boston, MA 02111-1307 USA
#
# Questions or comments on this program may be addressed to:
#
# LibraryFind
# 121 The Valley Library
# Corvallis OR 97331-4501
#
# http://libraryfind.org

class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.column :name,             :string, :limit => 25
      t.column :full_name,        :string, :limit => 100
      t.column :email,            :string
      t.column :hashed_password,  :string
      t.column :salt,             :string
      t.column :administrator,    :boolean, :default => false
    end
    
    # Create a default administrator account
    admin_user = User.create(:name => 'admin', :full_name => 'LibraryFind Admin',
      :email => 'you@example.com', :password => 'lfadministrator',
      :password_confirmation => 'lfadministrator', :administrator => true)
    admin_user.save!
    
  end

  def self.down
    drop_table :users
  end
end
