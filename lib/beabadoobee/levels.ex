defmodule Beabadoobee.Levels do
  alias Beabadoobee.State.LevelCooldowns

  def handle(%Nostrum.Struct.Message{} = msg) do
    if LevelCooldowns.guild_enabled(msg.guild_id) do
      if !LevelCooldowns.in_cooldown(msg.author.id) do
        new_xp = gen_xp()
        Beabadoobee.Database.Levels.upsert_xp(msg.guild_id, msg.author.id, new_xp)
        LevelCooldowns.enqueue(msg.author.id)
        member = Beabadoobee.Database.Levels.get_member(msg.guild_id, msg.author.id)
        old_level = calc_level(member.xp - new_xp)
        new_level = calc_level(member.xp)
        if new_level > old_level do
          guild = Beabadoobee.Database.Guilds.get_guild(msg.guild_id)
          case guild.level_up_channel_id do
            nil -> :ok
            0 -> Nostrum.Api.create_message(msg.channel_id, content: "#{Beabadoobee.Utils.format_ping({:user, msg.author.id})} just leveled up to level #{new_level}! meow meow")
            id -> Nostrum.Api.create_message(id, content: "#{Beabadoobee.Utils.format_ping({:user, msg.author.id})} just leveled up to level #{new_level}! meow meow")
          end
          reward = Beabadoobee.Database.RoleRewards.get_reward(msg.guild_id, new_level)
          if !is_nil(reward) do
            Nostrum.Api.modify_guild_member(msg.guild_id, msg.author.id, roles: [reward.role_id])
          end
        end
      end
    end
  end

  def gen_xp do
    Enum.random(15..25)
  end


  def calc_level(xp), do: calc_level(xp, {0, 0})
  def calc_level(xp, {level, temp_xp}) do
    if xp >= temp_xp do
      calc_level(xp, {level + 1, xp_for_level(level + 1)})
    else
      level - 1
    end
  end

  def xp_for_level(level) do
    ((5.0 / 6.0) * level * (2.0 * level * level + 27.0 * level + 91.0))
  end
end
