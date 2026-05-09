import connectDB from '@/config/database';
import Property from '@/models/Property';

async function getFeaturedProperties() {
  await connectDB();

  return Property.find({ is_featured: true }).lean();
}

async function getRecentProperties(limit = 3) {
  await connectDB();

  const properties = await Property.find({}).sort({ createdAt: -1 }).limit(limit).lean();
  return properties;
}

export { getFeaturedProperties, getRecentProperties };
