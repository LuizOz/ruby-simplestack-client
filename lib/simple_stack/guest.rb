module SimpleStack
  class Guest < Entity
    def disks
      cached_attributes[:disks] ||= SimpleStack::Collection.new hypervisor, self, "#{url}/disks", SimpleStack::Disk
    end

    def network_interfaces
      cached_attributes[:network_interfaces] ||= SimpleStack::Collection.new hypervisor, self, "#{url}/network_interfaces", SimpleStack::NetworkInterface
    end

    def snapshots
      cached_attributes[:snapshots] ||= SimpleStack::Collection.new hypervisor, self, "#{url}/snapshots", SimpleStack::Snapshot
    end

    def tags
      cached_attributes[:tags] ||= hypervisor.get("#{url}/tags").parsed_response
    end

    def add_tag(tag)
      hypervisor.post "#{url}/tags", :name => tag
      reload if cacheable?
      tag
    end

    def remove_tag(tag)
      hypervisor.delete "#{url}/tags/#{tag}"
      reload if cacheable?
      tag
    end

    def reboot(opts={:force => false})
      hypervisor.put "#{url}/reboot", :force => opts[:force]
    end

    def export(opts={})
      opts = {:to => "/tmp/export_file"}.merge(opts)
      file = File.open(opts[:to], "wb")

      hypervisor.get_stream("#{url}/export", file)

      opts[:to]
    ensure
      file.close rescue nil
    end

    def revert_to(snapshot)
      snapshot.revert
    end

    def clone(opts={})
      response = hypervisor.post("#{url}/clone", opts)
      entity_path = response.headers["location"].sub(/^\//, "").sub(/\/$/, "")
      entity_url = "#{connection.url}/#{entity_path}"
      new_item = SimpleStack::Guest.new hypervisor, self, entity_url
    end

    def insert_media(media_name, opts={})
      media_options = opts.merge(:name => media_name)
      hypervisor.put("#{url}/media_device", media_options)
      reload if cacheable?
    end

    def eject_media
      hypervisor.put("#{url}/media_device", :name => nil)
      reload if cacheable?
    end

    def inserted_media
      if cached_attributes.key? :inserted_media
        cached_attributes[:inserted_media]
      else
        cached_attributes[:inserted_media] = hypervisor.get("#{url}/media_device").parsed_response["name"]
      end
    end

    def power_state=(state)
      hypervisor.put "#{url}/power", :state => state
    end

    ["start", "stop", "force_stop", "pause", "resume"].each do |state|
      define_method(state) do
        self.power_state = state
      end
    end
  end
end
