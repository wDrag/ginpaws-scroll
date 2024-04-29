import Header from "../../components/Header/Header";

// eslint-disable-next-line react/prop-types
export const HeaderLayout = ({ children }) => {
    return (
        <div>
            <Header />
            {children}
        </div>
    );
};