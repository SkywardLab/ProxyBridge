using System;
using System.Reflection;
using System.Windows.Input;
using ProxyBridge.GUI.Common;

namespace ProxyBridge.GUI.ViewModels;

public class AboutViewModel
{
    public string Version { get; }
    public ICommand CloseCommand { get; }

    public AboutViewModel() : this(() => { })
    {
    }

    public AboutViewModel(Action onClose)
    {
        // AssemblyVersion (AssemblyName.Version) is strictly numeric — .NET drops any
        // "-Beta" suffix before it gets there. The csproj's <Version> (which does keep
        // suffixes like "4.0.8-Beta") is embedded as AssemblyInformationalVersionAttribute,
        // so read that instead to show the real product version, beta tag included.
        var infoVersion = Assembly.GetExecutingAssembly()
            .GetCustomAttribute<AssemblyInformationalVersionAttribute>()?.InformationalVersion;

        Version = !string.IsNullOrWhiteSpace(infoVersion)
            ? $"Version {infoVersion}"
            : "Version 1.0.0";

        CloseCommand = new RelayCommand(onClose);
    }
}
