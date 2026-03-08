using System;
using System.IO;
using System.IO.Compression;

class Program
{
    static int Main(string[] args)
    {
        if (args.Length < 1)
            return 1;

        int exitCode = 0;
        foreach (string arg in args)
        {
            if (!File.Exists(arg) || !arg.EndsWith(".zip", StringComparison.OrdinalIgnoreCase))
            {
                exitCode = 1;
                continue;
            }

            string fullPath = Path.GetFullPath(arg);
            string destDir = Path.Combine(Path.GetDirectoryName(fullPath)!, Path.GetFileNameWithoutExtension(fullPath));

            try
            {
                ZipFile.ExtractToDirectory(fullPath, destDir, overwriteFiles: true);
                File.Delete(fullPath);
            }
            catch
            {
                exitCode = 1;
            }
        }

        return exitCode;
    }
}
