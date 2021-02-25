module ModerationLogger
  include Constants

  class ContextInformation
    attr_reader :user, :mod, :reason, :dm_sent, :length
    def initialize(user, mod, reason, dm_sent, length)
      @user = user
      @mod = mod
      @reason = reason
      @dm_sent = dm_sent
      @length = length
    end
  end

  CONTEXT_INFORMATION ||= {}
  EMBED_COLOR ||= 0xFFD700

  module_function 

  def set_context(user, mod, reason, dm_sent, length: nil)
    CONTEXT_INFORMATION[user.id] = ContextInformation.new(user, mod, reason, dm_sent, length)
  end

  def log_warning(user_id)
    info = CONTEXT_INFORMATION[user_id]
    user = info.user
    mod = info.mod

    MOD_LOG.send_embed do |embed|
      embed.author = {
        name: "WARNING | #{user.distinct}",
        icon_url: user.avatar_url
      }
      embed.description = "**⚠ #{user.mention} was given a warning by #{mod.mention} (#{mod.distinct})**"
      embed.add_field(name: "Reason", value: info.reason.join(" "))
      embed.add_field(name: "Additional Information", value: "A DM couldn't be sent to this user.") unless info.dm_sent
      embed.footer = { 
        text: "User ID: #{info.user.id} | Staff ID: #{mod.id} | #{Time.new.utc.strftime("%Y-%m-%d at %l:%M %p UTC")}"
      }
      embed.color = EMBED_COLOR
    end

    CONTEXT_INFORMATION.delete(user_id)
  end

  def log_mute(user_id)
    info = CONTEXT_INFORMATION[user_id]
    user = info.user
    mod = info.mod

    MOD_LOG.send_embed do |embed|
      embed.author = {
        name: "MUTE | #{user.distinct}",
        icon_url: user.avatar_url
      }
      embed.description = "**🔇 #{user.mention} was muted by #{mod.mention} (#{mod.distinct}).**"
      embed.add_field(name: "Mute Length", value: info.length)
      embed.add_field(name: "Reason", value: info.reason.join(" "))
      embed.add_field(name: "Additional Information", value: "A DM couldn't be sent to this user.") unless info.dm_sent
      embed.footer = { 
        text: "User ID: #{user.id} | Staff ID: #{mod.id} | #{Time.new.utc.strftime("%Y-%m-%d at %l:%M %p UTC")}" 
      }
      embed.color = EMBED_COLOR
    end

    CONTEXT_INFORMATION.delete(user_id)
  end

  def log_unmute(user_id)
    info = CONTEXT_INFORMATION[user_id]
    user = info.user

    MOD_LOG.send_embed do |embed|
      embed.author = {
        name: "UNMUTE | #{user.distinct}",
        icon_url: user.avatar_url
      }
      embed.description = "**#{user.mention} was unmuted.**"
      embed.add_field(name: "Mute Length", value: info.length)
      embed.add_field(name: "Reason for Mute", value: info.reason.join(" "))
      embed.footer = {
        text: "User ID: #{user.id} | #{Time.new.utc.strftime("%Y-%m-%d at %l:%M %p UTC")}"
      }
      embed.color = EMBED_COLOR
    end

    CONTEXT_INFORMATION.delete(user_id)
  end
end