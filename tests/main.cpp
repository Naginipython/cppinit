#include <gtest/gtest.h>

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}

// Simply create new files or add to this file the following code:
/*
TEST(TestSuiteName, TestName) {
    EXPECT_EQ(1 == 1);
    EXPECT_TRUE(true);
    EXPECT_FALSE(false);
}

*/
