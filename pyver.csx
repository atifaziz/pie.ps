/* Copyright (c) 2019 Atif Aziz

MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

// Run with dotnet-script:
// https://www.nuget.org/packages/dotnet-script/0.52.0

// This script scrapes the Python downloads page for Windows and
// generates a CSV output of all releases (including pre-releases)
// that are designed for embeddeding. It is used to refresh the
// "pyver.csv" file. Typical usage is:
//
//     dotnet script pyver.csx > pyver.csv

#r "nuget:System.Reactive, 4.0.0"
#r "nuget:WebLinq, 1.0.0-ci-20180920T1656"

using System.Reactive;
using System.Reactive.Linq;
using System.Text.RegularExpressions;
using WebLinq;
using WebLinq.Html;
using static WebLinq.Modules.HttpModule;
using static System.Console;

var infos =
    from infos in
        Observable
            .ToArray(
                from dlp in
                    Http.WithConfig(Http.Config.WithHeader("Accept-Language", "en-US"))
                        .Get(new Uri("https://www.python.org/downloads/windows/"))
                        .Html()
                        .Content()
                from e in dlp.Links((href, a) => new { Url = new Uri(href), Text = Regex.Replace(a.InnerText, @"\s+", " ").Trim() })
                where Regex.IsMatch(e.Url.OriginalString, @"\bembed.+\.zip$", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant)
                   && !Regex.IsMatch(e.Text, @"\b(installer|MSI)\b")
                let nts = Regex.Replace(e.Url.Segments.Last(), @"\.zip$", string.Empty, RegexOptions.IgnoreCase | RegexOptions.CultureInvariant)
                               .Split('-')
                let vm = Regex.Match(nts[1], @"^([0-9](?:\.[0-9]){2,3})([a-z0-9]+)?")
                select new
                {
                    Version = vm.Value,
                    VersionPrefix = vm.Groups[1].Value,
                    VersionSuffix = vm.Groups[2].Value,
                    Architecture = Regex.Match(nts.Last(), @"^(win32|amd64)$").Value,
                    Url = e.Url.OriginalString,
                })
            .ToEnumerable()
    from e in infos
    orderby e.VersionPrefix,
            e.VersionSuffix.Length == 0 ? 1 : 0,
            e.VersionSuffix,
            e.Architecture
    select new
    {
        e.Version, e.VersionPrefix, e.VersionSuffix,
        e.Architecture,
        e.Url,
    };

WriteLine("version,version_prefix,version_suffix,architecture,url");
foreach (var e in infos)
    WriteLine(string.Join(",", e.Version, e.VersionPrefix, e.VersionSuffix, e.Architecture, e.Url));
