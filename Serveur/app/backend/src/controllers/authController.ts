import { Request, Response } from 'express';

export const authController = {
  login: async (req: Request, res: Response) => {
    try {
      const { email, password } = req.body;
      
      // Validate request body
      if (!email || !password) {
        return res.status(400).json({ message: 'Email and password are required' });
      }

      // Mock successful login for development
      const mockUser = {
        id: '123',
        email: email,
        name: 'Test User'
      };
      const mockToken = require('crypto').createHash('sha256').update('mock-jwt-token').digest('hex');
      const mockRefreshToken = require('crypto').createHash('sha256').update('mock-refresh-token').digest('hex');

      res.status(200).json({
        user: mockUser,
        token: mockToken,
        refreshToken: mockRefreshToken
      });
    } catch (error) {
      res.status(500).json({ message: 'Internal server error' });
    }
  },
  
  register: async (req: Request, res: Response) => {
    try {
      const { email, password, name } = req.body;

      // Validate request body
      if (!email || !password || !name) {
        return res.status(400).json({ message: 'Email, password and name are required' });
      }

      // Mock successful registration
      const mockUser = {
        id: '123',
        email,
        name
      };

      res.status(201).json({
        user: mockUser,
        message: 'Registration successful'
      });
    } catch (error) {
      res.status(500).json({ message: 'Internal server error' });
    }
  },

  logout: async (req: Request, res: Response) => {
    try {
      // Mock successful logout
      res.status(200).json({ message: 'Logged out successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Internal server error' });
    }
  },

  refreshToken: async (req: Request, res: Response) => {
    try {
      const { refreshToken } = req.body;

      if (!refreshToken) {
        return res.status(400).json({ message: 'Refresh token is required' });
      }

      // Mock successful token refresh
      const mockNewToken = 'new-mock-jwt-token';
      const mockNewRefreshToken = 'new-mock-refresh-token';

      res.status(200).json({
        token: mockNewToken,
        refreshToken: mockNewRefreshToken
      });
    } catch (error) {
      res.status(500).json({ message: 'Internal server error' });
    }
  }
}; 