<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;

class SqlFileSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 1. Danh sách file theo thứ tự
        $files = [
            'categories.sql',
            'brands.sql',
            'products.sql',
            'cities.sql',
            'districts.sql',
            'wards.sql',
            'hot_deals.sql',
        ];

        // 2. SỬA LỖI ĐƯỜNG DẪN TẠI ĐÂY
        // Thư mục sql/ nằm trực tiếp trong database/
        $path = database_path('sql/');

        // 3. Tắt kiểm tra khóa ngoại
        DB::statement('SET FOREIGN_KEY_CHECKS=0;');

        // 4. Lặp qua từng file và thực thi từng dòng
        foreach ($files as $file) {
            $this->command->info("Seeding file: $file");
            $filePath = $path . $file;

            if (!File::exists($filePath)) {
                $this->command->error("File not found: $filePath");
                continue;
            }

            // Mở file để đọc
            $handle = fopen($filePath, "r");
            if ($handle) {
                $statement = ''; // Biến đệm lưu trữ câu lệnh SQL

                // Đọc từng dòng của file
                while (($line = fgets($handle)) !== false) {
                    $trimmedLine = trim($line);

                    // Bỏ qua các dòng trống hoặc là comment SQL
                    if ($trimmedLine == '' || strpos($trimmedLine, '--') === 0 || strpos($trimmedLine, '#') === 0) {
                        continue;
                    }

                    // Thêm dòng hiện tại vào biến đệm
                    $statement .= $line;

                    // Nếu dòng này kết thúc bằng dấu chấm phẩy (;)
                    if (str_ends_with($trimmedLine, ';')) {
                        try {
                            // Thực thi câu lệnh đã gom
                            DB::unprepared($statement);
                        } catch (\Illuminate\Database\QueryException $e) {
                            $this->command->error("Error in $file: " . $e->getMessage());
                        }
                        
                        // Reset biến đệm để bắt đầu câu lệnh mới
                        $statement = '';
                    }
                }

                // Đóng file
                fclose($handle);
            } else {
                $this->command->error("Could not open file: $file");
            }
        }

        // 5. Bật lại kiểm tra khóa ngoại
        DB::statement('SET FOREIGN_KEY_CHECKS=1;');
    }
}