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
        self.role?(MOD_ROLE)
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