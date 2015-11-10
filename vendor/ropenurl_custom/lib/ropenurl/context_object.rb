module OpenURL

  class ContextObject
    require 'date'

    attr_accessor(:referent, :referringEntity, :requestor, :referrer, :serviceType, :resolver, :custom)
		attr_reader(:admin)
    @@defined_entities = {"rft"=>"referent", "rfr"=>"referrer", "rfe"=>"referring-entity", "req"=>"requestor", "svc"=>"service-type", "res"=>"resolver"}
    def initialize()
      @referent = ReferentEntity.new()
      @referringEntity = ReferringEntity.new()
      @requestor = RequestorEntity.new()
      @referrer = ReferrerEntity.new()
      @serviceType = [ServiceTypeEntity.new()]
      @resolver = [ResolverEntity.new()]
      @custom = []
      @admin = {"ctx_ver"=>{"label"=>"version", "value"=>"Z39.88-2004"}, "ctx_tim"=>{"label"=>"timestamp", "value"=>DateTime.now().to_s}, "ctx_id"=>{"label"=>"identifier", "value"=>""}, "ctx_enc"=>{"label"=>"encoding", "value"=>"info:ofi/enc:UTF-8"}}    
    end
    
    def xml
      require "rexml/document"
      doc = REXML::Document.new()
      coContainer = doc.add_element "ctx:context-objects"
      coContainer.add_namespace("ctx","info:ofi/fmt:xml:xsd:ctx")
      coContainer.add_namespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")
      coContainer.add_attribute("xsi:schemaLocation", "info:ofi/fmt:xml:xsd:ctx http://www.openurl.info/registry/docs/info:ofi/fmt:xml:xsd:ctx")
      co = coContainer.add_element "ctx:context-object"
      @admin.each_key {|k|
        co.add_attribute(@admin[k]["label"], @admin[k]["value"])
      }

      [@referent, @referringEntity, @requestor, @referrer].each {| ent |
        unless ent.empty?
          ent.xml(co)
        end
      }
      [@serviceType, @resolver, @custom].each {|entCont|
        entCont.each {|ent|
          unless ent.empty?
            ent.xml(co)
          end
        }
      }

      return doc.to_s
    end
    
    def sap2
      return xml
    end
    
    def kev(no_date=false)
      require 'cgi'
      kevs = ["url_ver=Z39.88-2004"]        
      @admin.each_key {|k|
        if k == "ctx_tim" && no_date
            next
        end
        if @admin[k]["value"]
          kevs.push(k+"="+CGI.escape(@admin[k]["value"]))
        end
      }

      [@referent, @referringEntity, @requestor, @referrer].each {| ent |
        unless ent.empty?
          kevs.push(ent.kev)
        end
      }
      [@serviceType, @resolver, @custom].each {|entCont|
        entCont.each {|ent|
          unless ent.empty?
            kevs.push(ent.kev)
          end
        }
      }  
        
      return kevs.join("&")
    end
    
    def to_hash
      co_hash = {"url_ver"=>"Z39.88-2004"}           
      @admin.each_key {|k|
        if @admin[k]["value"]
          co_hash[k]=@admin[k]["value"]
        end
      }

      [@referent, @referringEntity, @requestor, @referrer].each {| ent |
        unless ent.empty?
          co_hash.merge!(ent.to_hash)
        end
      }
      [@serviceType, @resolver, @custom].each {|entCont|
        entCont.each {|ent|
          unless ent.empty?
            co_hash.merge!(ent.to_hash)
          end
        }
      }  
        
      return co_hash
    end    
    
    def sap1
      return kev
    end
    
    def coins (classnames=nil, innerHTML=" ")
      require 'cgi'
      return "<span class='Z3988 "+classnames.to_s+"' title='"+CGI.escapeHTML(self.kev(true))+"'>"+innerHTML+"</span>"
    end
    
    def add_service_type_entity
      svc = ServiceTypeEntity.new
      @serviceType.push(svc)
      return @serviceType.index(svc)
    end

    def add_resolver_entity
      res = ResolverEntity.new
      @resolver.push(res)
      return @resolver.index(res)
    end  

    def add_custom_entity(abbr=nil, label=nil)
      cus = CustomEntity.new(abbr, label)
      @custom.push(cus)
      return @custom.index(cus)
    end  
      
    def set_administration_key(key, val)
      @admin[key]["value"] = val
    end

    
    def import_kev(kev)
      require 'cgi'
      co = CGI::parse(kev)
      co2 = {}
      co.each_key { |k|
      	co2[k] = co[k][0]
      }
      self.import_hash(co2)
    end
    
    def import_xml(xml)
			require "rexml/document"
			doc = REXML::Document.new xml
			ctx = REXML::XPath.first(doc, ".//ctx:context-object", {"ctx"=>"info:ofi/fmt:xml:xsd:ctx"})
			ctx.attributes.each_key { |k|				
				@admin.each_key { |a|
					if @admin[a]["label"] == k
						self.set_administration_key(a, ctx.attributes[k])
					end
				}
			}
			ctx.to_a.each { | ent |
				if @@defined_entities.value?(ent.name())
					var = @@defined_entities.keys[@@defined_entities.values.index(ent.name())]
					meth = "import_"+var+"_node"
					self.send(meth, ent)
				else
					self.import_custom_node(ent)
				end
			} 
    end
    
    def import_rft_node(node)
			self.import_xml_common(@referent, node)	
			self.import_xml_mbv_ref(@referent, node)
    end
    
    def import_rfe_node(node)
    	print node.to_a    	
			self.import_xml_common(@referringEntity, node)	    	
			self.import_xml_mbv_ref(@referringEntity, node)			
    end

    def import_rfr_node(node)
			self.import_xml_common(@referrer, node)	
			self.import_xml_mbv(@referrer, node)
    end
    
    def import_req_node(node)
			self.import_xml_common(@requestor, node)	    	
			self.import_xml_mbv(@requestor, node)			
    end
		
		def import_svc_node(node)
    	if @serviceType[0].empty?
    		key = 0
    	else
    		key = self.add_service_type_entity
    	end
			self.import_xml_common(@serviceType[key], node)				
			self.import_xml_mbv(@serviceType[key], node)			
		end
		
		def import_custom_node(node)
			key = self.add_custom_entity(node.name())
			self.import_xml_commom(@custom[key], node)
			self.import_xml_mbv(@custom[key], node)			
		end

    def import_res_node(node)

    	if @resolver[0].empty?
    		key = 0
    	else
    		key = self.add_resolver_entity
    	end
			self.import_xml_common(@resolver[key], node)	
			self.import_xml_mbv(@resolver[key], node)			
    end

		def import_xml_common(ent, node) 
			fmt = REXML::XPath.first(node, ".//ctx:format", {"ctx"=>"info:ofi/fmt:xml:xsd:ctx"})
			if fmt
				if fmt.has_text?
					ent.set_format(fmt.get_text.value)
				end
			end
			id = REXML::XPath.first(node, ".//ctx:identifier", {"ctx"=>"info:ofi/fmt:xml:xsd:ctx"})
			if id
				if id.has_text?
					ent.set_identifier(id.get_text.value)
				end		
			end
			priv = REXML::XPath.first(node, ".//ctx:private-data", {"ctx"=>"info:ofi/fmt:xml:xsd:ctx"})
			if priv
				if priv.has_text?
					ent.set_private_data(priv.get_text.value)
				end			
			end	
			ref = REXML::XPath.first(node, ".//ctx:metadata-by-ref", {"ctx"=>"info:ofi/fmt:xml:xsd:ctx"})					
			if ref
				ref.to_a.each { |r|
					if r.name() == "format"
						format = r.get_text.value
					else 
						location = r.get_text.value
					end
					ent.set_reference(location, format)
				}
			end
		end
		
		def import_xml_mbv(ent, node)
			mbv = REXML::XPath.first(node, ".//ctx:metadata-by-val", {"ctx"=>"info:ofi/fmt:xml:xsd:ctx"})
      
			if mbv        
				mbv.to_a.each { |m|
					ent.set_metadata(m.name(), m.get_text.value)
				}
			end			
		end

		def import_xml_mbv_ref(ent, node)
			ns = "info:ofi/fmt:xml:xsd:"+ent.format
			mbv = REXML::XPath.first(node, ".//fmt:"+ent.format, {"fmt"=>ns})					
			if mbv
				mbv.to_a.each { |m|
          if m.has_text?
            ent.set_metadata(m.name(), m.get_text.value)            
          end
          if m.has_elements?
            m.to_a.each { | md |
              if md.has_text?
                ent.set_metadata(md.name(), md.get_text.value)
              end
            }
          end
				}
			end					
		end
		
    def search_custom_entities(key, val)
      matches = []
      @custom.each { |cus|
        if cus.has_attribute?(key) and cus.key == val
          matches.push(@custom.index(cus))
        end
      }
      return matches
    end
    
    def import_hash(hash)    
      require 'cgi'
      ref = {}
      openurl_keys = ["url_ver", "url_tim", "url_ctx_fmt"]
      hash.each { |key, val|
        if openurl_keys.include?(key)
        elsif @admin.has_key?(key)
          self.set_administration_key(key, val)
        elsif key.match(/^[a-z]{3}_val_fmt$/)          
          (entity, v, fmt) = key.split("_")
          ent = self.translate_abbr(entity)  
          eval("@"+ent).set_format(val)
        elsif key.match(/^[a-z]{3}_ref/)
          (entity, v, fmt) = key.split("_")
          ent = self.translate_abbr(entity)
          unless ref[entity]
            if fmt
              ref_key = "format"
            else 
              ref_key = "location"
            end
            ref[entity] = [ref_key, val]
          else
            if ref[entity][0] == "format"
              eval("@"+ent).set_reference(val, ref[entity][1])
            else
              eval("@"+ent).set_reference(ref[entity][1], val)
            end
          end
        elsif key.match(/^[a-z]{3}_id$/)
          (entity, v) = key.split("_")
          ent = self.translate_abbr(entity)
          eval("@"+ent).set_identifier(val)      
        elsif key.match(/^[a-z]{3}_dat$/)
          (entity, v) = key.split("_")
          ent = self.translate_abbr(entity)
          eval("@"+ent).set_private_data(val)  
        else
          keyparts = key.split(".")            
          if keyparts.length > 1
            ent = self.translate_abbr(keyparts[0])
            eval("@"+ent).set_metadata(keyparts[1], val)
          else
            @referent.set_metadata(key, val)
          end
        end
      }  
      if not @referent.format
        @referent.set_format("journal")
      end
    end
    
    def translate_abbr(abbr)
      if @@defined_entities.has_key?abbr
        ent = @@defined_entities[abbr]
        if ent == "service-type"
          ent = "serviceType[0]"
        elsif ent == "resolver"
          ent = "resolver[0]"
        elsif ent == "referringEntity"      
          ent.downsize!
        end
      else
        idx = self.search_custom_entities("abbr", abbr)
        if idx.length == 0
          self.add_custom_entity(abbr)
          idx = self.search_custom_entities("abbr", abbr)
        end
        ent = "custom["+idx[0]+"]"
      end
      return ent
    end
   
    def resolve_doi(url, atitle)
      require 'net/http'
      require 'uri'
      buffer = Net::HTTP.get_response(URI.parse(url)).body
      #===================================================
      # this makes a doi request.  We now check the 
      # //doi_record/@type to make sure that the data
      # isn't null.  For this, we will use REXML
      #===================================================
      require "rexml/document"
      doc = REXML::Document.new buffer
      root = doc.root
      if root.elements["//doi_record"].attributes["type"]!="null"
        co = OpenURL::ContextObject.new
        keys = Hash.new 
        keys["aulast"] = root.elements["//journal_article_metadata/article/author/surname"].text
        keys["date"] = root.elements["//journal_article_metadata/article/date/year"].text
        keys["volume"] = root.elements["//journal_article_metadata/article/enumeration/volume"].text
        keys["issue"] = root.elements["//journal_article_metadata/article/enumeration/issue"].text
        keys["spage"] = root.elements["//journal_article_metadata/article/enumeration/first_page"].text
        keys["atitle"] = atitle
        keys["jtitle"] = root.elements["//journal_article_metadata/journal/full_title"].text
        keys["issn"] = root.elements["//journal_article_metadata/journal/issn[@type='print']"].text
        keys["eissn"] = root.elements["//journal_article_metadata/journal/issn[@type='electronic']"].text
        co.import_hash(keys)
        return co
      else
        return nil
      end
      
    end

    def resolve_pmid(id)
      require 'net/http'
      require 'uri'
      buffer = Net::HTTP.get_response(URI.parse(url)).body
      #===================================================
      # this makes a doi request.  We now check the
      # //doi_record/@type to make sure that the data
      # isn't null.  For this, we will use REXML
      #===================================================
      require "rexml/document"
      doc = REXML::Document.new buffer
      root = doc.root
      if root.elements["/ERROR"] != nil
        co = OpenURL::ContextObject.new
        keys = Hash.new 
        keys["rft_id"] = "info:doi/" + root.elements["//Item[@Name='DOI']"].text
        keys["volume"] = root.elements["//Item[@Name='Volume']"].text
        keys["issue"] = root.elements["//Item[@Name='Issue']"].text
        keys["pages"] = root.elements["//Item[@Name='Pages']"].text
        keys["atitle"] = root.elements["//Item[@Name='Title']"].text
        keys["jtitle"] = root.elements["//Item[@Name='FullJournal']"].text
        keys["issn"] = root.elements["//Item[@Name='ISSN']"].text
        keys["eissn"] = root.elements["//Item[@Name='ESSN']"].text

        #=========================================================
        # Time to handle Dates
        #=========================================================
        if root.elements["//Item[@Name='EPubDate']"].text != ""
           keys["date"] = root.elements["//Item[@Name='EPubDate']"].text
        else
           keys["date"] = root.elements["//Item[@Name='PubDate']"].text
        end

        if keys["date"] != ""
          tmpDate = keys["date"].substring(0,4)
          if keys["date"].index("jan"): keys["date"] = tmpDate + "01" 
          elsif keys["date"].index("feb"): keys["date"] = tmpDate + "02"
          elsif keys["date"].index("mar"): keys["date"] = tmpDate + "03"
          elsif keys["date"].index("apr"): keys["date"] = tmpDate + "04"
          elsif keys["date"].index("may"): keys["date"] = tmpDate + "05"
          elsif keys["date"].index("jun"): keys["date"] = tmpDate + "06"
          elsif keys["date"].index("jul"): keys["date"] = tmpDate + "07"
          elsif keys["date"].index("aug"): keys["date"] = tmpDate + "08"
          elsif keys["date"].index("sep"): keys["date"] = tmpDate + "09"
          elsif keys["date"].index("oct"): keys["date"] = tmpDate + "10"
          elsif keys["date"].index("nov"): keys["date"] = tmpDate + "11"
          elsif keys["date"].index("dec"): keys["date"] = tmpDate + "12"
          end
        end
        co.import_hash(keys)
        return co
      else
        return nil
      end


    end
 
    def import_context_object(context_object)
    	@admin.each_key { |k|
    		self.set_administration_key(k, context_object.admin[k]["value"])
    	}	
      [context_object.referent, context_object.referringEntity, context_object.requestor, context_object.referrer].each {| ent |
        unless ent.empty?
          ['identifier', 'format', 'private_data'].each { |var|
            unless ent.send(var).nil?
              eval("@"+ent.label.downcase).send('set_'+var,ent.send(var))
            end
          }
          unless ent.reference["format"].nil? or ent.reference["format"].nil?
            eval("@"+ent.label.downcase).set_reference(ent.reference["location"], ent.reference["format"])
          end
          ent.metadata.each_key { |k|
            unless ent.metadata[k].nil?
              eval("@"+ent.label.downcase).set_metadata(k, ent.metadata[k])
            end
          }
        end
      }
      context_object.serviceType.each { |svc|
        if @serviceType[0].empty?
          @serviceType[0] = svc
        else
          idx = self.add_service_type_entity
          @serviceType[idx] = svc
        end
          
      }
      context_object.resolver.each { |res|
        if @resolver[0].empty?
          @resolver[0] = res
        else
          idx = self.add_resolver_entity
          @resolver[idx] = red
        end
          
      }
      context_object.custom.each { |cus|
        idx = self.add_custom_entity(cus.abbr, cus.label)
        @custom[idx] = cus
      }
    end
  end

end
