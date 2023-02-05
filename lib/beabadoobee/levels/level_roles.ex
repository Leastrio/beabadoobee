defmodule Beabadoobee.Levels.LevelRoles do
  @level_5 Application.compile_env!(:beabadoobee, [:roles, :level_5])
  @level_10 Application.compile_env!(:beabadoobee, [:roles, :level_10])
  @level_15 Application.compile_env!(:beabadoobee, [:roles, :level_15])
  @level_20 Application.compile_env!(:beabadoobee, [:roles, :level_20])
  @level_25 Application.compile_env!(:beabadoobee, [:roles, :level_25])
  @level_30 Application.compile_env!(:beabadoobee, [:roles, :level_30])
  @level_35 Application.compile_env!(:beabadoobee, [:roles, :level_35])
  @level_40 Application.compile_env!(:beabadoobee, [:roles, :level_40])
  @level_45 Application.compile_env!(:beabadoobee, [:roles, :level_45])
  @level_50 Application.compile_env!(:beabadoobee, [:roles, :level_50])
  @level_55 Application.compile_env!(:beabadoobee, [:roles, :level_55])
  @level_60 Application.compile_env!(:beabadoobee, [:roles, :level_60])
  @guild_id Application.compile_env!(:beabadoobee, :guild_id)

  def handle_message(message) do
    cond do
      String.contains?(message.content, "you r now level 5! <3 <3") ->
        give_role(@level_5, message)
      String.contains?(message.content, "you r now level 10! <3 <3") ->
        give_role(@level_10, message)
      String.contains?(message.content, "you r now level 15! <3 <3") ->
        give_role(@level_15, message)
      String.contains?(message.content, "you r now level 20! <3 <3") ->
        give_role(@level_20, message)
      String.contains?(message.content, "you r now level 25! <3 <3") ->
        give_role(@level_25, message)
      String.contains?(message.content, "you r now level 30! <3 <3") ->
        give_role(@level_30, message)
      String.contains?(message.content, "you r now level 35! <3 <3") ->
        give_role(@level_35, message)
      String.contains?(message.content, "you r now level 40! <3 <3") ->
        give_role(@level_35, message)
      String.contains?(message.content, "you r now level 45! <3 <3") ->
        give_role(@level_35, message)
      String.contains?(message.content, "you r now level 50! <3 <3") ->
        give_role(@level_35, message)
      String.contains?(message.content, "you r now level 55! <3 <3") ->
        give_role(@level_35, message)
      String.contains?(message.content, "you r now level 60! <3 <3") ->
        give_role(@level_35, message)

      true ->
        :ok
    end
  end

  def give_role(level_id, %{mentions: [users]}) do
    user_id = users
      |> Map.get(:id)
    Nostrum.Api.add_guild_member_role(@guild_id, user_id, level_id, "Automatically added level role.")
  end
end
