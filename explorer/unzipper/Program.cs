using System;
using System.IO;
using System.IO.Compression;

class Program
{
    static int Main(string[] args)
    {
        if (args.Length < 1)
        {
            Console.Error.WriteLine("Usage: unzip.exe <file.zip>");
            return 1;
        }

        string zipPath = args[0];

        if (!File.Exists(zipPath))
        {
            Console.Error.WriteLine($"File not found: {zipPath}");
            return 1;
        }

        if (!zipPath.EndsWith(".zip", StringComparison.OrdinalIgnoreCase))
        {
            Console.Error.WriteLine("File is not a .zip archive.");
            return 1;
        }

        string fullPath = Path.GetFullPath(zipPath);
        string parentDir = Path.GetDirectoryName(fullPath)!;
        string folderName = Path.GetFileNameWithoutExtension(fullPath);
        string destDir = Path.Combine(parentDir, folderName);

        try
        {
            ZipFile.ExtractToDirectory(fullPath, destDir, overwriteFiles: true);
            File.Delete(fullPath);
            return 0;
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"Error: {ex.Message}");
            return 1;
        }
    }
}
