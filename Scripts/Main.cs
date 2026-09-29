using Godot;

public partial class Main : Node
{
    public override void _Ready()
    {
        if (HasNode("/root/PokiSDK"))
        {
            Node pokiSdk = GetNode("/root/PokiSDK");
            pokiSdk.Call("gameplayStart");
            GD.Print("Poki SDK succesvol geladen in het nieuwe project!");
        }
    }
}