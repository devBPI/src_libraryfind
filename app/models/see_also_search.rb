# LibraryFind - Quality find done better.
# Copyright (C) 2007 Oregon State University
# Copyright (C) 2009 Atos Origin France - Business Solution & Innovation
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
# Atos Origin France - 
# Tour Manhattan - La Défense (92)
# roger.essoh@atosorigin.com
#
# http://libraryfind.org
class SeeAlsoSearch < ActionController::Base
  
  if LIBRARYFIND_INDEXER.downcase == 'ferret' 
    require 'ferret'
    #  include FERRET
  elsif LIBRARYFIND_INDEXER.downcase == 'solr'
    require 'rubygems'
    require 'solr'
    include Solr
  end
  
  attr_reader :relations
  
  def initialize()
    super
  end
  
  def search_relations(query)
    logger.debug("[search_relations] query: #{query}")
    
    @relations = []
    
    if SEE_ALSO_ACTIVATE == 1
      if LIBRARYFIND_INDEXER.downcase == 'ferret'
        # todo
      else
        logger.debug("[search_relations] create cnx")
				@connection = Solr::Connection.new(Parameter.by_name('solr_requests'))
      end
      
      if !@connection.nil? and !query.blank?
        query = "searcher:("+UtilFormat.normalizeSolrKeyword(query)+")"
        if LIBRARYFIND_INDEXER.downcase == 'ferret'
          # todo
        else
          @connection.query(query, :rows => SEE_ALSO_MAX) do |hit|
            if defined?(hit["association"]) and !hit["association"].blank?
              _s = hit["association"].to_s
              logger.debug("[search_relations] s => #{_s}")
              _s.split(';').each do |a| 
                if !@relations.include?(a) and @relations.length() < SEE_ALSO_MAX
                  @relations << a
                end
              end
            end
          end
        end
      end
    else
      logger.debug("[search_relations] desabled")
    end
    
    logger.debug("[search_relations] nb relations #{@relations.length}")
    return @relations
  end
  
end
