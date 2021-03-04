class Discordrb::Member
  include Constants
  def has_permission?(perm_to_check)
    if perm_to_check == :cap 
      return self.id == CAP_ID
    elsif perm_to_check == :admin
      return self.defined_permission?(:administrator) || self.id == CAP_ID
    elsif perm_to_check == :mod
      # Allows admins and I to use commands even if we don't have the mod role
      if self.id == CAP_ID || self.defined_permission?(:administrator) ||
        self.role?(MOD_ROLE_ID)
        return true
      end
    end
    # Implicitly returns false if the above checks fail
    false
  end
end

class Discordrb::User
  include Constants
  # Used for cases where 'Member' methods get called on 'User' objects
  def method_missing(method, *args, &block)
    return nil
  end

  def has_permission?(perm_to_check)
    return nil
  end
end

class Discordrb::Message
  include Constants
  # Creates a message link for a given message.
  # @return  [String]               The url.
  def jump_url
    return "https://discordapp.com/channels/#{self.channel.server.id}/#{self.channel.id}/#{self.id}"
  end
end

class Discordrb::Bot
  include Constants
  def get_channel(channel)
    # Argument is a channel ID
    return channel(channel.resolve_id) rescue nil if channel.resolve_id != 0
    # Argument is a channel mention
    return parse_mention(channel) if channel =~ /<#\d+>/
  end

  def get_member(member)
    parsed_member = parse_mention(member)
    member(SERVER_ID, parsed_member&.id || member)
  end
end

class Rufus::Scheduler
  def end_job(job_id)
    job = job(job_id)
    job.unschedule
    job.kill
  end
end