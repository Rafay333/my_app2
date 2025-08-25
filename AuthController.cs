
        [HttpGet("test")]
        public IActionResult Test()
        {
            return Ok(new { message = "CORS is working!", timestamp = DateTime.UtcNow });
        }

        [HttpGet("test-db")]
        public async Task<IActionResult> TestDatabase()
        {
            try
            {
                // Test database connection
                var installerCount = await _context.Installers.CountAsync();
                
                // Get a sample installer (first 5 records)
                var sampleInstallers = await _context.Installers
                    .Take(5)
                    .Select(i => new { 
                        i.Int_number, 
                        i.Int_code, 
                        i.Int_type, 
                        i.Int_Branch 
                    })
                    .ToListAsync();

                return Ok(new
                {
                    message = "Database connection successful!",
                    totalInstallers = installerCount,
                    sampleData = sampleInstallers,
                    timestamp = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    message = "Database connection failed!",
                    error = ex.Message,
                    innerException = ex.InnerException?.Message,
                    timestamp = DateTime.UtcNow
                });
            }
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            try
            {
                // Log the incoming request
                Console.WriteLine($"Login attempt - Int_number: {request.Int_number}, Int_code: {request.Int_code}");
                
                // Validate input
                if (string.IsNullOrEmpty(request.Int_number) || 
                    string.IsNullOrEmpty(request.Int_code) || 
                    string.IsNullOrEmpty(request.Int_pass))
                {
                    return BadRequest(new { message = "All fields are required" });
                }

                // Test database connection first
                var installerCount = await _context.Installers.CountAsync();
                Console.WriteLine($"Total installers in database: {installerCount}");

                var installer = await _context.Installers
                    .FirstOrDefaultAsync(i => i.Int_number == request.Int_number &&
                                              i.Int_code == request.Int_code &&
                                              i.Int_pass == request.Int_pass);

                if (installer == null)
                {
                    Console.WriteLine($"No installer found with these credentials");
                    return Unauthorized(new { message = "Invalid credentials" });
                }

                Console.WriteLine($"Login successful for installer: {installer.Int_number}");
                var token = _jwt.GenerateToken(installer);

                return Ok(new
                {
                    message = "Login successful",
                    token = token,
                    installer.Int_number,
                    installer.Int_code,
                    installer.Int_type,
                    installer.Int_Branch
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Login error: {ex.Message}");
                Console.WriteLine($"Stack trace: {ex.StackTrace}");
                return StatusCode(500, new { message = "Internal server error", error = ex.Message });
            }
        }

